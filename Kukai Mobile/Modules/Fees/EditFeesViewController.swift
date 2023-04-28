//
//  EditFeesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2022.
//

import UIKit
import KukaiCoreSwift

protocol EditFeesViewControllerDelegate {
	func updateFees()
}

class EditFeesViewController: UIViewController {
	
	@IBOutlet weak var segmentedButton: UISegmentedControl!
	@IBOutlet weak var gasLimitTextField: ValidatorTextField!
	@IBOutlet weak var gasErrorLabel: UILabel!
	@IBOutlet weak var feeTextField: ValidatorTextField!
	@IBOutlet weak var feeErrorLabel: UILabel!
	@IBOutlet weak var storageLimitTextField: ValidatorTextField!
	@IBOutlet weak var storageErrorLabel: UILabel!
	@IBOutlet weak var maxStorageCostLbl: UILabel!
	private var infoIndex = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		let selectedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2"), NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 14)]
		let normalAttributes = [NSAttributedString.Key.foregroundColor: UIColor.colorNamed("TxtB6"), NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 14)]
		
		segmentedButton.setTitleTextAttributes(normalAttributes, for: .normal)
		segmentedButton.setTitleTextAttributes(selectedAttributes, for: .selected)
		
		feeErrorLabel.isHidden = true
		gasErrorLabel.isHidden = true
		storageErrorLabel.isHidden = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		refreshUI()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// If selected custom, and theres an error or the user never changed any of the fields, revert back to normal
		if segmentedButton.selectedSegmentIndex == 2 && (!feeTextField.isValid || !gasLimitTextField.isValid || !storageLimitTextField.isValid) {
			segmentedButton.selectedSegmentIndex = 0
			updateTransaction()
		}
	}
	
	func refreshUI() {
		segmentedButton.selectedSegmentIndex = TransactionService.shared.currentOperationsAndFeesData.type.rawValue
		segmentedButtonTapped(self.segmentedButton as Any)
		
		let xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		
		gasLimitTextField.validator = TokenAmountValidator(balanceLimit: TokenAmount(fromNormalisedAmount: 1_040_000, decimalPlaces: 1), decimalPlaces: 1)
		gasLimitTextField.validatorTextFieldDelegate = self
		gasLimitTextField.addDoneToolbar()
		let _ = gasLimitTextField.revalidateTextfield()
		
		storageLimitTextField.validator = TokenAmountValidator(balanceLimit: TokenAmount(fromNormalisedAmount: 60_000, decimalPlaces: 0), decimalPlaces: 0)
		storageLimitTextField.validatorTextFieldDelegate = self
		storageLimitTextField.addDoneToolbar()
		let _ = storageLimitTextField.revalidateTextfield()
		
		feeTextField.validator = TokenAmountValidator(balanceLimit: xtzBalance, decimalPlaces: 6)
		feeTextField.validatorTextFieldDelegate = self
		feeTextField.addDoneToolbar()
		let _ = feeTextField.revalidateTextfield()
	}
	
	@IBAction func segmentedButtonTapped(_ sender: Any) {
		TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: segmentedButton.selectedSegmentIndex) ?? .normal
		updateFeeDisplay()
		recordFee()
		
		if segmentedButton.selectedSegmentIndex != 2 {
			disableAllFields()
		} else {
			enableAllFields()
		}
	}
	
	func updateFeeDisplay() {
		gasLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.gasLimit.description
		storageLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.storageLimit.description
		feeTextField.text = TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation
		maxStorageCostLbl.text = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation
	}
	
	func recordFee() {
		if segmentedButton.selectedSegmentIndex == 2 {
			if feeTextField.isValid && gasLimitTextField.isValid && storageLimitTextField.isValid {
				let xtzAmount = XTZAmount(fromNormalisedAmount: feeTextField.text ?? "0", decimalPlaces: 6)
				let gasLimit = Int(gasLimitTextField.text ?? "0")
				let storageLimit = Int(storageLimitTextField.text ?? "0")
				
				TransactionService.shared.currentOperationsAndFeesData.setCustomFeesTo(feesTo: xtzAmount, gasLimitTo: gasLimit, storageLimitTo: storageLimit)
				updateTransaction()
			}
		}
		
		updateTransaction()
	}
	
	func updateTransaction() {
		TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: segmentedButton.selectedSegmentIndex) ?? .normal
		
		// Check if a previous bototm sheet is displaying a transaction, and update its fee
		if let parentVC = self.presentingViewController as? EditFeesViewControllerDelegate {
			parentVC.updateFees()
		}
		
		// Check if there is a full screen (possibly as well as above) displaying a transaction, and update its fee
		if let parentVC = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? EditFeesViewControllerDelegate {
			parentVC.updateFees()
		} else if let parentVC = (self.presentingViewController?.presentingViewController as? UINavigationController)?.viewControllers.last as? EditFeesViewControllerDelegate {
			parentVC.updateFees()
		}
	}
	
	func disableAllFields() {
		gasLimitTextField.isEnabled = false
		gasLimitTextField.alpha = 0.5
		feeTextField.isEnabled = false
		feeTextField.alpha = 0.5
		storageLimitTextField.isEnabled = false
		storageLimitTextField.alpha = 0.5
	}
	
	func enableAllFields() {
		gasLimitTextField.isEnabled = true
		gasLimitTextField.alpha = 1
		feeTextField.isEnabled = true
		feeTextField.alpha = 1
		storageLimitTextField.isEnabled = true
		storageLimitTextField.alpha = 1
	}
	
	
	@IBAction func feeInfoTapped(_ sender: Any) {
		infoIndex = 1
		self.performSegue(withIdentifier: "feeInfo", sender: nil)
	}
	
	@IBAction func gasLimitInfoTapped(_ sender: Any) {
		infoIndex = 2
		self.performSegue(withIdentifier: "feeInfo", sender: nil)
	}
	
	@IBAction func storageInfoTapped(_ sender: Any) {
		infoIndex = 3
		self.performSegue(withIdentifier: "feeInfo", sender: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? OnboardingPageViewController {
			dest.startIndex = infoIndex
		}
	}
}

extension EditFeesViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		recordFee()
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if !validated {
			if textfield == feeTextField {
				feeErrorLabel.isHidden = false
				
			} else if textfield == gasLimitTextField {
				gasErrorLabel.isHidden = false
				
			} else if textfield == storageLimitTextField {
				storageErrorLabel.isHidden = false
			}
		} else {
			if textfield == feeTextField {
				feeErrorLabel.isHidden = true
				
			} else if textfield == gasLimitTextField {
				gasErrorLabel.isHidden = true
				
			} else if textfield == storageLimitTextField {
				storageErrorLabel.isHidden = true
			}
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
