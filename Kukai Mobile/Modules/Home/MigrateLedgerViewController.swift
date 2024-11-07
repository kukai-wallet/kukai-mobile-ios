//
//  MigrateLedgerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/10/2024.
//

import UIKit
import KukaiCoreSwift

class MigrateLedgerViewController: UIViewController {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var migrateButton: CustomisableButton!
	@IBOutlet weak var cancelButton: CustomisableButton!
	
	public var walletToMigrate: WalletMetadata? = nil
	public var newUUID: String? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		migrateButton.customButtonType = .destructive
		cancelButton.customButtonType = .primary
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		containerView.layoutIfNeeded()
		GradientView.add(toView: containerView, withType: .modalBackground)
		
		messageLabel.text = "Are you sure you want to migrate \"\(walletToMigrate?.hdWalletGroupName ?? "")\" to this new device?"
	}

	@IBAction func migrateTapped(_ sender: Any) {
		if let metadata = walletToMigrate,
		   let newID = newUUID,
		   WalletCacheService().migrateLedger(metadata: metadata, toNewUUID: newID),
		   let accountsVC = (self.presentingViewController as? UINavigationController)?.viewControllers.first(where: { $0 is AccountsViewController }) {
			
			let parentNav = (self.presentingViewController as? UINavigationController)
			self.dismiss(animated: true)
			parentNav?.popToViewController(accountsVC, animated: true)
			
		} else {
			self.windowError(withTitle: "error".localized(), description: "error-unknown".localized())
		}
	}
	
	@IBAction func cancelTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
}
