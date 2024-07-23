//
//  AddressTypeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/12/2022.
//

import UIKit

class AddressTypeCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var checkmarkImage: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		containerView.gradientType = .tableViewCell
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
		
		if selected {
			checkmarkImage.image = UIImage(named: "btnChecked")
			
		} else {
			checkmarkImage.image = UIImage(named: "btnUnchecked")
		}
    }
}
