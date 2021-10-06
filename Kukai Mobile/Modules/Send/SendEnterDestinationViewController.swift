//
//  SendEnterDestinationViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import KukaiCoreSwift

class SendEnterDestinationViewController: UIViewController {

	@IBOutlet weak var textfield: UITextField!
	
	private let scanner = ScanViewController()
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func scanQRCode(_ sender: Any) {
		scanner.delegate = self
		self.present(scanner, animated: true, completion: nil)
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		guard let enteredText = textfield.text, let walletType = DependencyManager.shared.selectedWallet?.type else {
			self.alert(errorWithMessage: "Unable to get data")
			return
		}
		
		TransactionService.shared.sendData.destiantion = enteredText
		
		if walletType == .ledger {
			self.performSegue(withIdentifier: "ledgerApproveSegue", sender: self)
			
		} else {
			self.performSegue(withIdentifier: "waitSegue", sender: self)
		}
	}
}

extension SendEnterDestinationViewController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		self.textfield.text = code
	}
}
