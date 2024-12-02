//
//  LearnMoreItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2024.
//

import UIKit

class LearnMoreItemCell: UITableViewCell {
	
	@IBOutlet weak var titleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		GradientView.add(toView: self.contentView, withType: .tableViewCell)
	}
}
