//
//  EditFeesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2022.
//

import UIKit
import KukaiCoreSwift

class EditFeesViewController: UIViewController {
	
	@IBOutlet weak var segmentedButton: UISegmentedControl!
	@IBOutlet weak var gasLimitTextField: ValidatorTextField!
	@IBOutlet weak var feeTextField: ValidatorTextField!
	@IBOutlet weak var storageLimitTextField: ValidatorTextField!
	@IBOutlet weak var maxStorageCostTextField: UITextField!
	@IBOutlet weak var saveButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		segmentedButton.selectedSegmentIndex = TransactionService.shared.currentOperationsAndFeesData.type.rawValue
		segmentedButtonTapped(self.segmentedButton as Any)
		
		let xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		
		gasLimitTextField.validator = TokenAmountValidator(balanceLimit: TokenAmount(fromNormalisedAmount: 1_040_000, decimalPlaces: 1), decimalPlaces: 1)
		gasLimitTextField.validatorTextFieldDelegate = self
		gasLimitTextField.addDoneToolbar()
		
		storageLimitTextField.validator = TokenAmountValidator(balanceLimit: TokenAmount(fromNormalisedAmount: 60_000, decimalPlaces: 0), decimalPlaces: 0)
		storageLimitTextField.validatorTextFieldDelegate = self
		storageLimitTextField.addDoneToolbar()
		
		feeTextField.validator = TokenAmountValidator(balanceLimit: xtzBalance, decimalPlaces: 6)
		feeTextField.validatorTextFieldDelegate = self
		feeTextField.addDoneToolbar()
	}
	
	@IBAction func segmentedButtonTapped(_ sender: Any) {
		TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: segmentedButton.selectedSegmentIndex) ?? .normal
		updateFeeDisplay()
		
		if segmentedButton.selectedSegmentIndex != 2 {
			disableAllFields()
		} else {
			enableAllFields()
		}
	}
	
	@IBAction func saveTapped(_ sender: Any) {
		if segmentedButton.selectedSegmentIndex == 2 {
			let xtzAmount = XTZAmount(fromNormalisedAmount: feeTextField.text ?? "0", decimalPlaces: 6)
			let gasLimit = Int(gasLimitTextField.text ?? "0")
			let storageLimit = Int(storageLimitTextField.text ?? "0")
			
			TransactionService.shared.currentOperationsAndFeesData.setCustomFeesTo(feesTo: xtzAmount, gasLimitTo: gasLimit, storageLimitTo: storageLimit)
		}
		
		TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: segmentedButton.selectedSegmentIndex) ?? .normal
		self.dismissBottomSheet()
	}
	
	func updateFeeDisplay() {
		gasLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.gasLimit.description
		storageLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.storageLimit.description
		feeTextField.text = TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation
		maxStorageCostTextField.text = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation
	}
	
	func disableAllFields() {
		gasLimitTextField.isEnabled = false
		feeTextField.isEnabled = false
		storageLimitTextField.isEnabled = false
	}
	
	func enableAllFields() {
		gasLimitTextField.isEnabled = true
		feeTextField.isEnabled = true
		storageLimitTextField.isEnabled = true
	}
}

extension EditFeesViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if !validated {
			textfield.backgroundColor = .red
		} else {
			textfield.backgroundColor = .white
		}
	}
}
