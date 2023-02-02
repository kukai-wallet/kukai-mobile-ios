//
//  SendTokenAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import KukaiCoreSwift

class SendTokenAmountViewController: UIViewController {

	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var toStackViewRegular: UIStackView!
	
	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var regularAddressLabel: UILabel!
	
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var inputContainer: UIView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var textfield: ValidatorTextField!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var fiatValueLabel: UILabel?
	@IBOutlet weak var maxButton: UIButton!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var infoButton: CustomisableButton!
	@IBOutlet weak var feeButton: CustomisableButton!
	
	@IBOutlet weak var reviewButton: UIButton!
	
	private var gradientLayer = CAGradientLayer()
	private var selectedToken: Token? = nil
	
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		selectedToken = TransactionService.shared.sendData.chosenToken
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
		balanceLabel.text = token.balance.normalisedRepresentation
		textfield.validator = TokenAmountValidator(balanceLimit: token.balance, decimalPlaces: token.decimalPlaces)
		symbolLabel.text = token.symbol
		fiatValueLabel?.text = " "
		feeValueLabel?.text = "0 tez"
		tokenIcon.addTokenIcon(token: token)
		
		
		// Textfield
		textfield.validatorTextFieldDelegate = self
		textfield.validator = TokenAmountValidator(balanceLimit: token.balance, decimalPlaces: token.decimalPlaces)
		textfield.addDoneToolbar(onDone: (target: self, action: #selector(estimateFee)))
		
		feeButton.configuration?.imagePlacement = .trailing
		feeButton.configuration?.imagePadding = 6
		
		reviewButton.isEnabled = false
		reviewButton.layer.opacity = 0.5
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		gradientLayer.removeFromSuperlayer()
		gradientLayer = reviewButton.addGradientButtonPrimary(withFrame: reviewButton.bounds)
	}
	
	@IBAction func maxButtonTapped(_ sender: UIButton) {
		if let balance = balanceLabel.text {
			textfield.text = balance
			if textfield.revalidateTextfield() {
				estimateFee()
			}
		}
	}
	
	@objc func estimateFee() {
		textfield.resignFirstResponder()
		
		guard let destination = TransactionService.shared.sendData.destination else {
			self.alert(errorWithMessage: "Can't find destination")
			return
		}
		
		self.showLoadingModal(completion: nil)
		let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata
		if let token = TransactionService.shared.sendData.chosenToken, let textDecimal = Decimal(string: textfield.text ?? "") {
			
			let amount = TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces)
			let operations = OperationFactory.sendOperation(amount, of: token, from: selectedWalletMetadata.address, to: destination)
			TransactionService.shared.sendData.chosenAmount = amount
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey) { [weak self] estimationResult in
				self?.hideLoadingModal(completion: nil)
				
				switch estimationResult {
					case .success(let estimatedOperations):
						TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOperations)
						self?.feeValueLabel?.text = estimatedOperations.map({ $0.operationFees.allFees() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " XTZ"
						self?.reviewButton.isEnabled = true
						self?.reviewButton.layer.opacity = 1
						
					case .failure(let estimationError):
						self?.alert(errorWithMessage: "\(estimationError)")
						self?.reviewButton.isEnabled = false
						self?.reviewButton.layer.opacity = 0.5
				}
			}
		}
	}
}

extension SendTokenAmountViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		//estimateFee()
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			inputContainer.borderColor = .clear
			inputContainer.borderWidth = 0
			
			if let token = TransactionService.shared.sendData.chosenToken, let textDecimal = Decimal(string: text) {
				self.fiatValueLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces))
			}
			
		} else if text != "" {
			inputContainer.borderColor = .red
			inputContainer.borderWidth = 1
			
			self.fiatValueLabel?.text = "0"
		}
	}
}
