//
//  FavouriteTokenEditCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class FavouriteTokenEditCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var containerView: UIView!
	
	var gradientLayer = CAGradientLayer()
	private var myReorderImage: UIImage? = nil
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		for subViewA in self.subviews {
			if (subViewA.classForCoder.description() == "UITableViewCellReorderControl") {
				for subViewB in subViewA.subviews {
					if (subViewB.isKind(of: UIImageView.classForCoder())) {
						let imageView = subViewB as! UIImageView
						if (self.myReorderImage == nil) {
							let myImage = imageView.image
							myReorderImage = myImage?.withRenderingMode(.alwaysTemplate)
						}
						imageView.image = self.myReorderImage
						imageView.tintColor = UIColor.colorNamed("Grey1200")
						break
					}
				}
				break
			}
		}
	}
}
