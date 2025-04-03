//
//  SendTokenAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import KukaiCoreSwift

class SendTokenAmountViewController: UIViewController {
	
	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var inputContainer: UIView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var textfield: ValidatorTextField!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var fiatValueLabel: UILabel?
	@IBOutlet weak var maxButton: UIButton!
	
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var maxWarningLabel: UILabel!
	@IBOutlet weak var reviewButton: CustomisableButton!
	
	private var selectedToken: Token? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		selectedToken = TransactionService.shared.sendData.chosenToken
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
		balanceLabel.text = token.availableBalance.normalisedRepresentation
		symbolLabel.text = token.symbol
		fiatValueLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
		tokenIcon.addTokenIcon(token: token)
		
		
		// Textfield
		textfield.validatorTextFieldDelegate = self
		textfield.validator = TokenAmountValidator(balanceLimit: token.availableBalance, decimalPlaces: token.decimalPlaces)
		textfield.addDoneToolbar()
		textfield.numericAndSeperatorOnly = true
		
		errorLabel.isHidden = true
		maxWarningLabel.isHidden = true
		reviewButton.customButtonType = .primary
		reviewButton.isEnabled = false
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		textfield.becomeFirstResponder()
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.navigationController?.popToDetails()
	}
	
	@IBAction func maxButtonTapped(_ sender: UIButton) {
		textfield.text = selectedToken?.availableBalance.normalisedRepresentation ?? ""
		let _ = textfield.revalidateTextfield()
	}
	
	@IBAction func reviewButtonTapped(_ sender: Any) {
		self.textfield.resignFirstResponder()
		estimateFeeAndNavigate()
	}
	
	func estimateFeeAndNavigate() {
		guard let destination = TransactionService.shared.sendData.destination, let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else {
			self.windowError(withTitle: "error".localized(), description: "error-no-destination".localized())
			return
		}
		
		if let token = TransactionService.shared.sendData.chosenToken, let amount = TokenAmount(fromNormalisedAmount: textfield.text ?? "", decimalPlaces: token.decimalPlaces) {
			self.showLoadingView()
			
			let operations = OperationFactory.sendOperation(amount, of: token, from: selectedWalletMetadata.address, to: destination)
			TransactionService.shared.sendData.chosenAmount = amount
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey, isRemote: false) { [weak self] estimationResult in
				
				switch estimationResult {
					case .success(let estimationResult):
						TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimationResult.operations)
						TransactionService.shared.currentForgedString = estimationResult.forgedString
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

extension SendTokenAmountViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		guard let token = TransactionService.shared.sendData.chosenToken else {
			return
		}
		
		if validated, let textDecimal = Decimal(string: text) {
			self.errorLabel.isHidden = true
			self.validateMaxXTZ(input: text)
			self.fiatValueLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces))
			self.reviewButton.isEnabled = true
			
		} else if text != "" {
			errorLabel.isHidden = false
			self.fiatValueLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
			self.reviewButton.isEnabled = false
			self.maxWarningLabel.isHidden = true
			
		} else {
			self.errorLabel.isHidden = true
			self.maxWarningLabel.isHidden = true
			self.fiatValueLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	func validateMaxXTZ(input: String) {
		if selectedToken?.isXTZ() == true, let balance = selectedToken?.availableBalance, let inputAmount = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6), balance == inputAmount  {
			maxWarningLabel.isHidden = false
		} else {
			maxWarningLabel.isHidden = true
		}
	}
}
