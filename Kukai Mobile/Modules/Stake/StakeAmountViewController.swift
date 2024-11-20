//
//  StakeAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/11/2024.
//

import UIKit
import KukaiCoreSwift

class StakeAmountViewController: UIViewController {

	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var bakerSplitValueLabel: UILabel!
	@IBOutlet weak var bakerSpaceValueLabel: UILabel!
	@IBOutlet weak var bakerRewardsValueLabel: UILabel!
	
	@IBOutlet weak var tokenNameLabel: UILabel!
	@IBOutlet weak var tokenBalanceLabel: UILabel!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var tokenSysmbolLabel: UILabel!
	@IBOutlet weak var textfield: ValidatorTextField!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var maxButton: UIButton!
	
	@IBOutlet weak var warningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	
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
		
		
		
		// Token data
		tokenBalanceLabel.text = token.availableBalance.normalisedRepresentation
		tokenSysmbolLabel.text = token.symbol
		fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
		tokenIcon.addTokenIcon(token: token)
		
		
		// Textfield
		textfield.validatorTextFieldDelegate = self
		textfield.validator = TokenAmountValidator(balanceLimit: token.availableBalance, decimalPlaces: token.decimalPlaces)
		textfield.addDoneToolbar()
		textfield.numericAndSeperatorOnly = true
		
		errorLabel.isHidden = true
		warningLabel.isHidden = true
		reviewButton.customButtonType = .primary
		reviewButton.isEnabled = false
    }
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func reviewTapped(_ sender: Any) {
		self.textfield.resignFirstResponder()
		estimateFeeAndNavigate()
	}
	
	@IBAction func maxTapped(_ sender: Any) {
		textfield.text = ((selectedToken?.availableBalance ?? .zero()) - XTZAmount(fromNormalisedAmount: 1)).normalisedRepresentation
		let _ = textfield.revalidateTextfield()
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
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey) { [weak self] estimationResult in
				
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

extension StakeAmountViewController: ValidatorTextFieldDelegate {
	
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
			self.fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces))
			self.reviewButton.isEnabled = true
			
		} else if text != "" {
			errorLabel.isHidden = false
			self.fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
			self.reviewButton.isEnabled = false
			self.warningLabel.isHidden = true
			
		} else {
			self.errorLabel.isHidden = true
			self.warningLabel.isHidden = true
			self.fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: .zero())
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	func validateMaxXTZ(input: String) {
		if selectedToken?.isXTZ() == true, let balance = selectedToken?.availableBalance, let inputAmount = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6), balance == inputAmount  {
			warningLabel.isHidden = false
		} else {
			warningLabel.isHidden = true
		}
	}
}
