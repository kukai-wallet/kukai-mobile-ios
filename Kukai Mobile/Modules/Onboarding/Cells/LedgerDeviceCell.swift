//
//  LedgerDeviceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit

class LedgerDeviceCell: UITableViewCell {

	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var checkedImage: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup(title: String, uuid: String) {
		self.titleLabel.text = title
		self.subtitleLabel.text = "UUID: \(uuid)"
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkedImage?.image = UIImage(named: "btnChecked")
		} else {
			checkedImage?.image = UIImage(named: "btnUnchecked")
		}
	}
}
