//
//  SendCollectibleAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/01/2023.
//

import Foundation
import UIKit
import KukaiCoreSwift

class SendCollectibleAmountViewController: UIViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	
	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	@IBOutlet weak var collectibleImage: UIImageView!
	@IBOutlet weak var collectibleName: UILabel!
	
	@IBOutlet weak var quantityStackView: UIStackView!
	@IBOutlet weak var quantityContainer: UIView!
	@IBOutlet weak var quantityMinusButton: CustomisableButton!
	@IBOutlet weak var quantityTextField: ValidatorTextField!
	@IBOutlet weak var quantityPlusButton: CustomisableButton!
	@IBOutlet weak var maxButton: UIButton!
	
	@IBOutlet weak var reviewButton: CustomisableButton!
	
	private var selectedToken: NFT? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		selectedToken = TransactionService.shared.sendData.chosenNFT
		guard let token = selectedToken else {
			self.windowError(withTitle: "error".localized(), description: "error-no-token".localized())
			return
		}
		
		// To section
		if let alias = TransactionService.shared.sendData.destinationAlias {
			addressIcon.image = TransactionService.shared.sendData.destinationIcon
			addressAliasLabel.text = alias
			addressLabel.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			
		} else {
			addressIcon.image = TransactionService.shared.sendData.destinationIcon
			addressAliasLabel.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			addressLabel.isHidden = true
		}
		
		
		// Token data
		if token.balance == 1 {
			quantityStackView.isHidden = true
		} else {
			let amountDisplay = token.balance > 100 ? "99+" : token.balance.description
			maxButton.setTitle("Max \(amountDisplay)", for: .normal)
		}
		
		MediaProxyService.load(url: MediaProxyService.url(fromUri: selectedToken?.displayURI, ofFormat: MediaProxyService.Format.small.rawFormat()), to: collectibleImage, withCacheType: .temporary, fallback: UIImage())
		collectibleName.text = selectedToken?.name ?? ""
		
		
		// Textfield
		quantityTextField.text = TransactionService.shared.sendData.chosenAmount?.normalisedRepresentation ?? "1"
		quantityTextField.validatorTextFieldDelegate = self
		quantityTextField.validator = NumberValidator(min: 1, max: token.balance, decimalPlaces: 0)
		quantityTextField.addDoneToolbar()
		quantityTextField.numericAndSeperatorOnly = true
		
		reviewButton.customButtonType = .primary
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.startListeningForKeyboard()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.navigationController?.popToDetails()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.stopListeningForKeyboard()
	}
	
	@IBAction func reviewButtonTapped(_ sender: Any) {
		self.quantityTextField.resignFirstResponder()
		estimateFeeAndNavigate()
	}
	
	func estimateFeeAndNavigate() {
		quantityTextField.resignFirstResponder()
		
		guard let destination = TransactionService.shared.sendData.destination, let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else {
			self.windowError(withTitle: "error".localized(), description: "error-no-destination".localized())
			return
		}
		
		if let nft = TransactionService.shared.sendData.chosenNFT, let textDecimal = Decimal(string: quantityTextField.text ?? "") {
			self.showLoadingView()
			
			let amount = TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: nft.decimalPlaces)
			let operations = OperationFactory.sendOperation(textDecimal, ofNft: nft, from: selectedWalletMetadata.address, to: destination)
			TransactionService.shared.sendData.chosenAmount = amount
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey, isRemote: false) { [weak self] estimationResult in
				DispatchQueue.main.async {
					switch estimationResult {
						case .success(let result):
							TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: result.operations)
							TransactionService.shared.currentForgedString = result.forgedString
							self?.loadingViewHideActivityAndFade()
							self?.performSegue(withIdentifier: "confirm", sender: nil)
							
						case .failure(let estimationError):
							self?.hideLoadingView()
							self?.windowError(withTitle: "error".localized(), description: estimationError.description)
					}
				}
			}
		}
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

extension SendCollectibleAmountViewController {
	
	func startListeningForKeyboard() {
		NotificationCenter.default.addObserver(self, selector: #selector(customKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(customLeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func stopListeningForKeyboard() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func customKeyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			let whereKeyboardWillGoToo = ((self.scrollView.frame.height + self.view.safeAreaInsets.bottom) - keyboardSize.height)
			let whereNeedsToBeDisplayed = (reviewButton.convert(CGPoint(x: 0, y: 0), to: scrollView).y + reviewButton.frame.height + 8).rounded(.up)
			
			if whereKeyboardWillGoToo < whereNeedsToBeDisplayed {
				self.scrollView.contentOffset = CGPoint(x: 0, y: (whereNeedsToBeDisplayed - whereKeyboardWillGoToo))
			}
		}
	}
	
	@objc func customLeyboardWillHide(notification: NSNotification) {
		if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
		}
	}
}
