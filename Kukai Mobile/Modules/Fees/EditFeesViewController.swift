//
//  EditFeesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2022.
//

import UIKit
import KukaiCoreSwift

protocol EditFeesViewControllerDelegate {
	func updateFees(isFirstCall: Bool)
}

class EditFeesViewController: UIViewController {
	
	@IBOutlet weak var customSegmetnedContainer: UIView!
	@IBOutlet weak var normalButton: UIButton!
	@IBOutlet weak var fastButton: UIButton!
	@IBOutlet weak var customButton: UIButton!
	@IBOutlet weak var selectionSeperatorLeft: UIView!
	@IBOutlet weak var selectionSeperatorRight: UIView!
	
	@IBOutlet weak var gasLimitTextField: ValidatorTextField!
	@IBOutlet weak var gasErrorLabel: UILabel!
	@IBOutlet weak var feeTextField: ValidatorTextField!
	@IBOutlet weak var feeErrorLabel: UILabel!
	@IBOutlet weak var storageLimitTextField: ValidatorTextField!
	@IBOutlet weak var storageErrorLabel: UILabel!
	@IBOutlet weak var maxStorageCostLbl: UILabel!
	
	private var infoIndex = 0
	private var selectedSegmentIndex = 0
	private var isWalletConnectOp = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		gasLimitTextField.accessibilityIdentifier = "gas-limit-textfield"
		feeTextField.accessibilityIdentifier = "fee-textfield"
		storageLimitTextField.accessibilityIdentifier = "storage-limit-textfield"
		
		if let _ = TransactionService.shared.walletConnectOperationData.request?.topic {
			isWalletConnectOp = true
		}
		
		feeErrorLabel.isHidden = true
		gasErrorLabel.isHidden = true
		storageErrorLabel.isHidden = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.view.layoutIfNeeded()
		refreshUI()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// If selected custom, and theres an error or the user never changed any of the fields, revert back to normal
		if selectedSegmentIndex == 2 && (!feeTextField.isValid || !gasLimitTextField.isValid || !storageLimitTextField.isValid) {
			selectedSegmentIndex = 0
			updateTransaction()
		}
	}
	
	func refreshUI() {
		if isWalletConnectOp {
			selectedSegmentIndex = TransactionService.shared.currentRemoteOperationsAndFeesData.type.rawValue
		} else {
			selectedSegmentIndex = TransactionService.shared.currentOperationsAndFeesData.type.rawValue
		}
		
		if selectedSegmentIndex == 0 {
			normalButtonTapped(normalButton)
		} else if selectedSegmentIndex == 1 {
			fastButtonTapped(fastButton)
		} else {
			customButtonTapped(customButton)
		}
		
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
	
	func updateFeeDisplay() {
		if isWalletConnectOp {
			gasLimitTextField.text = TransactionService.shared.currentRemoteOperationsAndFeesData.gasLimit.description
			storageLimitTextField.text = TransactionService.shared.currentRemoteOperationsAndFeesData.storageLimit.description
			feeTextField.text = TransactionService.shared.currentRemoteOperationsAndFeesData.fee.normalisedRepresentation
			maxStorageCostLbl.text = TransactionService.shared.currentRemoteOperationsAndFeesData.maxStorageCost.normalisedRepresentation
			
		} else {
			gasLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.gasLimit.description
			storageLimitTextField.text = TransactionService.shared.currentOperationsAndFeesData.storageLimit.description
			feeTextField.text = TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation
			maxStorageCostLbl.text = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation
		}
	}
	
	func recordFee() {
		if selectedSegmentIndex == 2 {
			if feeTextField.isValid && gasLimitTextField.isValid && storageLimitTextField.isValid {
				let xtzAmount = XTZAmount(fromNormalisedAmount: feeTextField.text ?? "0", decimalPlaces: 6)
				let gasLimit = Int(gasLimitTextField.text ?? "0")
				let storageLimit = Int(storageLimitTextField.text ?? "0")
				
				if isWalletConnectOp {
					TransactionService.shared.currentRemoteOperationsAndFeesData.setCustomFeesTo(feesTo: xtzAmount, gasLimitTo: gasLimit, storageLimitTo: storageLimit)
				} else {
					TransactionService.shared.currentOperationsAndFeesData.setCustomFeesTo(feesTo: xtzAmount, gasLimitTo: gasLimit, storageLimitTo: storageLimit)
				}
				
				updateTransaction()
			}
		}
		
		updateTransaction()
	}
	
	func updateTransaction() {
		if isWalletConnectOp {
			TransactionService.shared.currentRemoteOperationsAndFeesData.type = TransactionService.FeeType(rawValue: selectedSegmentIndex) ?? .normal
		} else {
			TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: selectedSegmentIndex) ?? .normal
		}
		
		// Check if a previous bototm sheet is displaying a transaction, and update its fee
		if let parentVC = self.presentingViewController as? EditFeesViewControllerDelegate {
			parentVC.updateFees(isFirstCall: false)
		}
		
		// Check if there is a full screen (possibly as well as above) displaying a transaction, and update its fee
		if let parentVC = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? EditFeesViewControllerDelegate {
			parentVC.updateFees(isFirstCall: false)
			
		} else if let parentVC = (self.presentingViewController?.presentingViewController as? UINavigationController)?.viewControllers.last as? EditFeesViewControllerDelegate {
			parentVC.updateFees(isFirstCall: false)
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
	
	func segmentedButtonTapped() {
		if isWalletConnectOp {
			TransactionService.shared.currentRemoteOperationsAndFeesData.type = TransactionService.FeeType(rawValue: selectedSegmentIndex) ?? .normal
		} else {
			TransactionService.shared.currentOperationsAndFeesData.type = TransactionService.FeeType(rawValue: selectedSegmentIndex) ?? .normal
		}
		
		updateFeeDisplay()
		recordFee()
		
		if selectedSegmentIndex != 2 {
			disableAllFields()
		} else {
			enableAllFields()
		}
	}
	
	@IBAction func normalButtonTapped(_ sender: UIButton) {
		selectedSegmentIndex = 0
		applySelectedStyle(toButton: sender)
		applyNormalStyle(toButton: fastButton)
		applyNormalStyle(toButton: customButton)
		selectionSeperatorLeft.isHidden = true
		selectionSeperatorRight.isHidden = false
		
		segmentedButtonTapped()
	}
	
	@IBAction func fastButtonTapped(_ sender: UIButton) {
		selectedSegmentIndex = 1
		applySelectedStyle(toButton: sender)
		applyNormalStyle(toButton: normalButton)
		applyNormalStyle(toButton: customButton)
		selectionSeperatorLeft.isHidden = true
		selectionSeperatorRight.isHidden = true
		
		segmentedButtonTapped()
	}
	
	@IBAction func customButtonTapped(_ sender: UIButton) {
		selectedSegmentIndex = 2
		applySelectedStyle(toButton: sender)
		applyNormalStyle(toButton: normalButton)
		applyNormalStyle(toButton: fastButton)
		selectionSeperatorLeft.isHidden = false
		selectionSeperatorRight.isHidden = true
		
		segmentedButtonTapped()
	}
	
	private func applySelectedStyle(toButton button: UIButton) {
		button.backgroundColor = .colorNamed("BG6")
		button.isSelected = true
		
		for layer in button.layer.sublayers ?? [] {
			if layer.shadowPath != nil {
				layer.removeFromSuperlayer()
			}
		}
		
		button.addShadow(color: .black.withAlphaComponent(0.04), opacity: 1, offset: CGSize(width: 0, height: 3), radius: 1)
		button.addShadow(color: .black.withAlphaComponent(0.12), opacity: 1, offset: CGSize(width: 0, height: 3), radius: 8)
	}
	
	private func applyNormalStyle(toButton button: UIButton) {
		button.backgroundColor = .clear
		button.isSelected = false
		
		for layer in button.layer.sublayers ?? [] {
			if layer.shadowPath != nil {
				layer.removeFromSuperlayer()
			}
		}
	}
	
	@IBAction func feeInfoTapped(_ sender: Any) {
		infoIndex = 0
		self.performSegue(withIdentifier: "feeInfo", sender: nil)
	}
	
	@IBAction func gasLimitInfoTapped(_ sender: Any) {
		infoIndex = 1
		self.performSegue(withIdentifier: "feeInfo", sender: nil)
	}
	
	@IBAction func storageInfoTapped(_ sender: Any) {
		infoIndex = 2
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
				feeErrorLabel.text = "Invalid amount"
				feeErrorLabel.isHidden = false
				
			} else if textfield == gasLimitTextField {
				gasErrorLabel.text = "Invalid amount. Must be a positive whole number"
				gasErrorLabel.isHidden = false
				
			} else if textfield == storageLimitTextField {
				storageErrorLabel.text = "Invalid amount. Must be a positive whole number"
				storageErrorLabel.isHidden = false
			}
		} else {
			if textfield == feeTextField {
				feeErrorLabel.text = ""
				feeErrorLabel.isHidden = true
				
			} else if textfield == gasLimitTextField {
				gasErrorLabel.text = ""
				gasErrorLabel.isHidden = true
				
				var forgedString = ""
				var numberOfOperations = 0
				if isWalletConnectOp {
					forgedString = TransactionService.shared.currentRemoteForgedString
					numberOfOperations = TransactionService.shared.currentRemoteOperationsAndFeesData.selectedOperationsAndFees().count
				} else {
					forgedString = TransactionService.shared.currentForgedString
					numberOfOperations = TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees().count
				}
				
				let newFee = FeeEstimatorService.fee(forGasLimit: Int(text) ?? 0, forgedHexString: forgedString, numberOfOperations: numberOfOperations)
				feeTextField.text = newFee.normalisedRepresentation
				
			} else if textfield == storageLimitTextField {
				storageErrorLabel.text = ""
				storageErrorLabel.isHidden = true
				
				if let networkConstants = DependencyManager.shared.tezosNodeClient.networkConstants {
					let newMaxStorageCost = FeeEstimatorService.feeForBurn(Int(text) ?? 0, withConstants: networkConstants)
					maxStorageCostLbl.text = newMaxStorageCost.normalisedRepresentation
				}
			}
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
