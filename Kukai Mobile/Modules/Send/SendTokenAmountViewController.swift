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
	
	@IBOutlet weak var maxWarningLabel: UILabel!
	@IBOutlet weak var reviewButton: CustomisableButton!
	
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
		symbolLabel.text = token.symbol
		fiatValueLabel?.text = " "
		tokenIcon.addTokenIcon(token: token)
		
		
		// Textfield
		textfield.validatorTextFieldDelegate = self
		textfield.validator = TokenAmountValidator(balanceLimit: token.balance, decimalPlaces: token.decimalPlaces)
		textfield.addDoneToolbar()
		
		maxWarningLabel.isHidden = true
		reviewButton.customButtonType = .primary
		reviewButton.isEnabled = false
    }
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.navigationController?.popToDetails()
	}
	
	@IBAction func maxButtonTapped(_ sender: UIButton) {
		if let balance = balanceLabel.text {
			textfield.text = balance
			maxWarningLabel.isHidden = false
			
			if textfield.revalidateTextfield() {
				textfield.resignFirstResponder()
			}
		}
	}
	
	@IBAction func reviewButtonTapped(_ sender: Any) {
		self.textfield.resignFirstResponder()
		estimateFeeAndNavigate()
	}
	
	func estimateFeeAndNavigate() {
		guard let destination = TransactionService.shared.sendData.destination, let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else {
			self.alert(errorWithMessage: "Can't find destination")
			return
		}
		
		if let token = TransactionService.shared.sendData.chosenToken, let textDecimal = Decimal(string: textfield.text ?? "") {
			self.showLoadingModal()
			
			let amount = TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces)
			let operations = OperationFactory.sendOperation(amount, of: token, from: selectedWalletMetadata.address, to: destination)
			TransactionService.shared.sendData.chosenAmount = amount
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey) { [weak self] estimationResult in
				
				switch estimationResult {
					case .success(let estimatedOperations):
						TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOperations)
						
						self?.hideLoadingModal(completion: { [weak self] in
							self?.performSegue(withIdentifier: "confirm", sender: nil)
						})
						
					case .failure(let estimationError):
						self?.hideLoadingModal(completion: { [weak self] in
							self?.alert(errorWithMessage: "\(estimationError)")
						})
				}
			}
		}
	}
}

extension SendTokenAmountViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
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
			
			self.reviewButton.isEnabled = true
			
		} else if text != "" {
			inputContainer.borderColor = .red
			inputContainer.borderWidth = 1
			
			self.fiatValueLabel?.text = "0"
			self.reviewButton.isEnabled = false
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
