//
//  AddressTypeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/12/2022.
//

import UIKit

class AddressTypeCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var checkmarkImage: UIImageView!
	
	var gradientLayer = CAGradientLayer()
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
		
		if selected {
			checkmarkImage.image = UIImage(named: "radial-checked")
			
		} else {
			checkmarkImage.image = UIImage(named: "radial-unchecked")
		}
    }
}
