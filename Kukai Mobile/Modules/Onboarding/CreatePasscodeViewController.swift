//
//  CreatePasscodeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/07/2023.
//

import UIKit

class CreatePasscodeViewController: UIViewController {

	@IBOutlet weak var hiddenTextfield: ValidatorTextField!
	@IBOutlet weak var digitView1: UIView!
	@IBOutlet weak var digitView2: UIView!
	@IBOutlet weak var digitView3: UIView!
	@IBOutlet weak var digitView4: UIView!
	@IBOutlet weak var digitView5: UIView!
	@IBOutlet weak var digitView6: UIView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		hiddenTextfield.addDoneToolbar()
		hiddenTextfield.validator = LengthValidator(min: 6, max: 6)
		hiddenTextfield.validatorTextFieldDelegate = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		hiddenTextfield.becomeFirstResponder()
	}
	
	func updateDigitViewsWithLength(length: Int) {
		let colorOn = UIColor.colorNamed("BGB4")
		let colorOff = UIColor.colorNamed("BGB0")
		
		if length > 0 {
			digitView1.backgroundColor = colorOn
		} else {
			digitView1.backgroundColor = colorOff
		}
		
		if length > 1 {
			digitView2.backgroundColor = colorOn
		} else {
			digitView2.backgroundColor = colorOff
		}
		
		if length > 2 {
			digitView3.backgroundColor = colorOn
		} else {
			digitView3.backgroundColor = colorOff
		}
		
		if length > 3 {
			digitView4.backgroundColor = colorOn
		} else {
			digitView4.backgroundColor = colorOff
		}
		
		if length > 4 {
			digitView5.backgroundColor = colorOn
		} else {
			digitView5.backgroundColor = colorOff
		}
		
		if length > 5 {
			digitView6.backgroundColor = colorOn
		} else {
			digitView6.backgroundColor = colorOff
		}
	}
}

extension CreatePasscodeViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return false
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		updateDigitViewsWithLength(length: text.count)
		
		if validated {
			StorageService.setPasswordEnabled(true)
			StorageService.setPassword(text)
			self.performSegue(withIdentifier: "confirm", sender: nil)
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
