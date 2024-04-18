//
//  TokenContractViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/12/2022.
//

import UIKit

class TokenContractViewController: UIViewController {
	
	@IBOutlet weak var tokenIdLabel: UILabel!
	@IBOutlet weak var contractLabel: UILabel!
	
	private var tokenID = ""
	private var tokenAddress = ""
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tokenIdLabel.text = tokenID
		contractLabel.text = tokenAddress
	}
	
	func setup(tokenId: String, contractAddress: String) {
		tokenID = tokenId
		tokenAddress = contractAddress
	}
	
	@IBAction func copyTokenIdTapped(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = tokenIdLabel.text
	}
	
	@IBAction func copyTokenContractTapped(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = contractLabel.text
	}
	
	@IBAction func viewOnBCDTapped(_ sender: Any) {
		guard let url = URL(string: "https://better-call.dev/mainnet/\(contractLabel.text ?? "")/operations?token_id=\(tokenIdLabel.text ?? "0")") else {
			return
		}
		
		UIApplication.shared.open(url, completionHandler: nil)
	}
}
