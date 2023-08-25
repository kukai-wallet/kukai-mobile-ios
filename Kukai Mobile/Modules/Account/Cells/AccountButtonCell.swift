//
//  AccountButtonCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2023.
//

import UIKit

class AccountButtonCell: UITableViewCell {

	@IBOutlet weak var button: CustomisableButton!
	
	public weak var delegate: UITableViewCellButtonDelegate? = nil
	
	func setup(data: AccountButtonData, delegate: UITableViewCellButtonDelegate?) {
		button.setTitle(data.title, for: .normal)
		button.customButtonType = data.buttonType
		button.accessibilityIdentifier = data.accessibilityId
		
		self.delegate = delegate
	}

	@IBAction func buttonTapped(_ sender: UIButton) {
		self.delegate?.tableViewCellButtonTapped(sender: sender)
	}
}
