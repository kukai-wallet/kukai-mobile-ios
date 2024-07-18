//
//  ThemeChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/06/2023.
//

import UIKit

class ThemeChoiceCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var themeLabel: UILabel!
	@IBOutlet weak var checkedImage: UIImageView!
	
	var gradientLayer = CAGradientLayer()
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkedImage.image = UIImage(named: "btnChecked")
		} else {
			checkedImage.image = UIImage(named: "btnUnchecked")
		}
	}
}
