//
//  AlreadyHaveWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class AlreadyHaveWalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		tableView.delegate = self
		tableView.dataSource = self
    }
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 4
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlreadyHaveAWalletCell", for: indexPath) as? AlreadyHaveAWalletCell else {
			return UITableViewCell()
		}
		
		switch indexPath.row {
			case 0:
				cell.iconView.image = UIImage(named: "WalletSocial")
				cell.titleLabel.text = "Use Social"
				cell.descriptionLabel.text = "Sign in with your preferred social account"
				
			case 1:
				cell.iconView.image = UIImage(named: "WalletRestore")
				cell.titleLabel.text = "Restore with a Recovery Phrase"
				cell.descriptionLabel.text = "Import accounts using your recovery phrase from Kukai or another wallet"
				
			case 2:
				cell.iconView.image = UIImage(named: "WalletLedger")
				cell.titleLabel.text = "Connect with Ledger"
				cell.descriptionLabel.text = "Add accounts from your Bluetooth hardware wallet"
			
			case 3:
				cell.iconView.image = UIImage(named: "WalletWatch")
				cell.titleLabel.text = "Watch a Tezos Address"
				cell.descriptionLabel.text = "Watch a public address or .tez domain"
				
			default:
				cell.iconView.image = UIImage()
				cell.titleLabel.text = ""
				cell.descriptionLabel.text = ""
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.row {
			case 0:
				self.performSegue(withIdentifier: "social", sender: nil)
				
			case 1:
				self.performSegue(withIdentifier: "phrase", sender: nil)
				
			case 2:
				self.alert(withTitle: "Under Construction", andMessage: "coming soon")
				
			case 3:
				self.performSegue(withIdentifier: "watch", sender: nil)
				
			default:
				self.alert(withTitle: "Under Construction", andMessage: "coming soon")
		}
	}
}
