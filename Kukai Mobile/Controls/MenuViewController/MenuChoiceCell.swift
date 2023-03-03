//
//  MenuChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2023.
//

import UIKit

class MenuChoiceCell: UITableViewCell {

	@IBOutlet weak var selectedView: UIImageView!
	@IBOutlet weak var choiceLabel: UILabel!
	@IBOutlet weak var iconView: UIImageView!
	
	func setTick() {
		let image = UIImage(named: "Check")?.resizedImage(Size: CGSize(width: 15, height: 13))
		selectedView.image = image?.withTintColor(.colorNamed("TxtMenuContext"))
	}
	
	func removeTick() {
		selectedView.image = nil
	}
}
