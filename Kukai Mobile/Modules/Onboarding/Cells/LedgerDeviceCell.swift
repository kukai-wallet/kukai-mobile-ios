//
//  LedgerDeviceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit

class LedgerDeviceCell: UITableViewCell {

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var uuidLabel: UILabel!
	
	public static let reuseIdentifier = "ledgerDeviceCell"
	
	func setup(name: String, uuid: String) {
		self.nameLabel.text = name
		self.uuidLabel.text = uuid
	}
}
