//
//  EstimatedTotalCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class EstimatedTotalCell: UITableViewCell {

	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var totalEstButton: UIButton!
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		var image = UIImage(named: "info-template")
		image = image?.resizedImage(Size: CGSize(width: 13, height: 13))
		image = image?.withTintColor(UIColor.colorNamed("Grey1100"))
		
		totalEstButton.setImage(image, for: .normal)
		totalEstButton.tintColor = UIColor.colorNamed("Grey1100")
	}
}
