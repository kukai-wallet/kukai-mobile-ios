//
//  AccountReceiveAssetsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2023.
//

import UIKit

class AccountReceiveAssetsCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var qrButton: CustomisableButton!
	@IBOutlet weak var copyButton: CustomisableButton!
	
	var gradientLayer: CAGradientLayer = CAGradientLayer()
	public weak var delegate: UITableViewCellButtonDelegate? = nil
	
	func setup(delegate: UITableViewCellButtonDelegate?) {
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
