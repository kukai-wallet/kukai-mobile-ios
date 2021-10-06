//
//  SendEnterAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import KukaiCoreSwift

class SendEnterAmountViewController: UIViewController {

	@IBOutlet weak var textfield: UITextField!
	@IBOutlet weak var continueButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func continueTapped(_ sender: Any) {
		guard let token = TransactionService.shared.sendData.chosenToken, let enteredText = textfield.text, let amount = TokenAmount(fromNormalisedAmount: enteredText, decimalPlaces: token.decimalPlaces) else {
			self.alert(errorWithMessage: "Unable to get data")
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = amount
		self.performSegue(withIdentifier: "enterDestination", sender: self)
	}
}
