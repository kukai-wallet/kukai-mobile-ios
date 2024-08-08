//
//  AccountReceiveAssetsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2023.
//

import UIKit

class AccountReceiveAssetsCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var receiveAssetsTitle: UILabel!
	@IBOutlet weak var qrButton: CustomisableButton!
	@IBOutlet weak var copyButton: CustomisableButton!
	
	public weak var delegate: UITableViewCellButtonDelegate? = nil
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup(delegate: UITableViewCellButtonDelegate?) {
		receiveAssetsTitle.accessibilityIdentifier = "account-receive-assets-header"
		qrButton.customButtonType = .secondary
		qrButton.accessibilityIdentifier = AccountViewModel.accessibilityIdentifiers.qr
		copyButton.customButtonType = .secondary
		copyButton.accessibilityIdentifier = AccountViewModel.accessibilityIdentifiers.copy
		
		self.delegate = delegate
    }
	
	@IBAction func qrButtonTapped(_ sender: UIButton) {
		self.delegate?.tableViewCellButtonTapped(sender: sender)
	}
	
	@IBAction func copyButtonTapped(_ sender: UIButton) {
		self.delegate?.tableViewCellButtonTapped(sender: sender)
	}
}
