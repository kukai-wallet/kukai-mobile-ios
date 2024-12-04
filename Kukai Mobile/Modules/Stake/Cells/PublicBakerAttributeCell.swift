//
//  PublicBakerAttributeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/12/2024.
//

import UIKit

class PublicBakerAttributeCell: UITableViewCell {
	
	@IBOutlet weak var attributeTitleLabel: UILabel!
	@IBOutlet weak var attributeLabel: UILabel!
	
	public func setup(data: PublicBakerAttributeData) {
		attributeTitleLabel.text = data.title
		attributeLabel.text = data.value
		
		if data.valueWarning {
			attributeLabel.textColor = .colorNamed("TxtAlert4")
		} else {
			attributeLabel.textColor = .colorNamed("Txt8")
		}
	}
}
