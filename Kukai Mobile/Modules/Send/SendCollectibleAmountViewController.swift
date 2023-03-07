//
//  SendCollectibleAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/01/2023.
//

import Foundation

import UIKit
import KukaiCoreSwift

class SendCollectibleAmountViewController: UIViewController, EditFeesViewControllerDelegate {
	
	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var toStackViewRegular: UIStackView!
	
	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var regularAddressLabel: UILabel!
	
	@IBOutlet weak var collectibleImage: UIImageView!
	
	@IBOutlet weak var quantityContainer: UIView!
	@IBOutlet weak var quantityMinusButton: CustomisableButton!
	@IBOutlet weak var quantityTextField: ValidatorTextField!
	@IBOutlet weak var quantityPlusButton: CustomisableButton!
	@IBOutlet weak var maxButton: UIButton!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	
	@IBOutlet weak var reviewButton: UIButton!
	
	private var gradientLayer = CAGradientLayer()
	private var selectedToken: NFT? = nil
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		selectedToken = TransactionService.shared.sendData.chosenNFT
		guard let token = selectedToken else {
			self.alert(errorWithMessage: "Error finding token info")
			return
		}
		
		// To section
		if let alias = TransactionService.shared.sendData.destinationAlias {
			toStackViewRegular.isHidden = true
			addressAliasLabel.text = alias
			addressIcon.image = TransactionService.shared.sendData.destinationIcon
			addressLabel.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			
		} else {
			toStackViewSocial.isHidden = true
			regularAddressLabel.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
		}
		
		
		// Token data
		if token.balance == 1 {
			maxButton.isHidden = true
		} else {
			maxButton.setTitle("  MAX (\(token.balance))  ", for: .normal)
		}
		
		feeValueLabel?.text = "0 tez"
		MediaProxyService.load(url: MediaProxyService.url(fromUri: selectedToken?.displayURI, ofFormat: .small), to: collectibleImage, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: collectibleImage.frame.size)
		
		
		// Textfield
		quantityTextField.text = TransactionService.shared.sendData.chosenAmount?.normalisedRepresentation ?? "1"
		quantityTextField.validatorTextFieldDelegate = self
		quantityTextField.validator = NumberValidator(min: 1, max: token.balance, decimalPlaces: 0)
		quantityTextField.addDoneToolbar(onDone: (target: self, action: #selector(estimateFee)))
		
		updateFees()
		feeButton.configuration?.imagePlacement = .trailing
		feeButton.configuration?.imagePadding = 6
		feeButton.isEnabled = false
		
		reviewButton.isEnabled = false
		reviewButton.layer.opacity = 0.5
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		estimateFee()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		gradientLayer.removeFromSuperlayer()
		gradientLayer = reviewButton.addGradientButtonPrimary(withFrame: reviewButton.bounds)
	}
	
	@objc func estimateFee() {
		quantityTextField.resignFirstResponder()
		
		guard let destination = TransactionService.shared.sendData.destination else {
			self.alert(errorWithMessage: "Can't find destination")
			return
		}
		
		
		self.showLoadingModal(completion: nil)
		let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata
		if let nft = TransactionService.shared.sendData.chosenNFT, let textDecimal = Decimal(string: quantityTextField.text ?? "") {
			
			let amount = TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: nft.decimalPlaces)
			let operations = OperationFactory.sendOperation(textDecimal, ofNft: nft, from: selectedWalletMetadata.address, to: destination)
			TransactionService.shared.sendData.chosenAmount = amount
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey) { [weak self] estimationResult in
				self?.hideLoadingModal(completion: nil)
				
				switch estimationResult {
					case .success(let estimatedOperations):
						TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOperations)
						self?.feeValueLabel?.text = estimatedOperations.map({ $0.operationFees.allFees() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " XTZ"
						self?.feeButton.isEnabled = true
						self?.reviewButton.isEnabled = true
						self?.reviewButton.layer.opacity = 1
						
					case .failure(let estimationError):
						self?.alert(errorWithMessage: "\(estimationError)")
						self?.feeButton.isEnabled = false
						self?.reviewButton.isEnabled = false
						self?.reviewButton.layer.opacity = 0.5
				}
			}
		}
	}
	
	func updateFees() {
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		
		feeValueLabel.text = (feesAndData.fee + feesAndData.maxStorageCost).normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	@IBAction func minusTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == 1 {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = (amount - TokenAmount(fromNormalisedAmount: 1, decimalPlaces: nft.decimalPlaces))
		quantityTextField.text = TransactionService.shared.sendData.chosenAmount?.normalisedRepresentation
		let _ = quantityTextField.revalidateTextfield()
		estimateFee()
	}
	
	@IBAction func plusTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down) {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = (amount + TokenAmount(fromNormalisedAmount: 1, decimalPlaces: nft.decimalPlaces))
		quantityTextField.text = TransactionService.shared.sendData.chosenAmount?.normalisedRepresentation
		let _ = quantityTextField.revalidateTextfield()
		estimateFee()
	}
	
	@IBAction func maxTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down) {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = TokenAmount(fromNormalisedAmount: nft.balance, decimalPlaces: nft.decimalPlaces)
		quantityTextField.text = TransactionService.shared.sendData.chosenAmount?.normalisedRepresentation
		let _ = quantityTextField.revalidateTextfield()
		estimateFee()
	}
}

extension SendCollectibleAmountViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			quantityTextField.borderColor = .clear
			quantityTextField.borderWidth = 1
			
		} else if text != "" {
			quantityTextField.borderColor = .red
			quantityTextField.borderWidth = 1
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
