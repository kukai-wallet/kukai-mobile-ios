//
//  BackUpCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2023.
//

import UIKit

class BackUpCell: UITableViewCell {

	@IBOutlet weak var backUpButton: CustomisableButton!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet var descriptionToButtonConstraint: NSLayoutConstraint!
	
	private var backupText: String? = nil
	private var descriptionToEdgeConstraint: NSLayoutConstraint? = nil
	private let addressWarningText = "The key for this account has been compromised in a recent security breach at Web3Auth social login service.\n\nAn attacker may have access to this account. You should move your XTZ, NFTs, and any other tokens to a new account.\n\nDo not send any more assets to this account."
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		backUpButton.customButtonType = .secondary
		backUpButton.accessibilityIdentifier = "account-backup-button"
		
		backupText = descriptionLabel.text
		if let container = descriptionLabel.superview {
			descriptionToEdgeConstraint = descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
		}
    }
	
	func setup(hasAddressWarning: Bool) {
		descriptionLabel.text = hasAddressWarning ? addressWarningText : backupText
		descriptionLabel.accessibilityIdentifier = hasAddressWarning ? "account-address-warning" : nil
		backUpButton.isHidden = hasAddressWarning
		
		if hasAddressWarning {
			descriptionToButtonConstraint.isActive = false
			descriptionToEdgeConstraint?.isActive = true
		} else {
			descriptionToEdgeConstraint?.isActive = false
			descriptionToButtonConstraint.isActive = true
		}
	}
}
