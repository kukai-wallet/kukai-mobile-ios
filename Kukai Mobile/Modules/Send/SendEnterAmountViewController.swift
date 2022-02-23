//
//  SendEnterAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

class SendEnterAmountViewController: UIViewController {

	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var textfield: UITextField!
	@IBOutlet weak var errorMessage: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var fiatValue: UIView!
	@IBOutlet weak var feeValue: UILabel!
	@IBOutlet weak var reviewButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		addressAliasLabel.text = TransactionService.shared.sendData.destinationAlias
		addressLabel.text = TransactionService.shared.sendData.destination
	}
	
	@IBAction func reviewTapped(_ sender: Any) {
	}
}
