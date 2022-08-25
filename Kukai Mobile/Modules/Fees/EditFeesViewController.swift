//
//  EditFeesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2022.
//

import UIKit

class EditFeesViewController: UIViewController {
	
	@IBOutlet weak var segmentedButton: UISegmentedControl!
	@IBOutlet weak var gasLimitTextField: UITextField!
	@IBOutlet weak var feeTextField: UITextField!
	@IBOutlet weak var storageLimitTextField: UITextField!
	@IBOutlet weak var maxStorageCostTextField: UITextField!
	@IBOutlet weak var saveButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		disableAllFields()
	}
	
	@IBAction func segmentedButtonTapped(_ sender: Any) {
		if segmentedButton.selectedSegmentIndex != 2 {
			disableAllFields()
		} else {
			enableAllFields()
		}
	}
	
	@IBAction func saveTapped(_ sender: Any) {
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
