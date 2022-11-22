//
//  FavouriteTokenEditCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class FavouriteTokenEditCell: UITableViewCell {
	
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var containerView: UIView!
	
	private var gradient = CAGradientLayer()
	private var correctFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
	private var myReorderImage: UIImage? = nil
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	public func addGradientBackground(withFrame: CGRect) {
		correctFrame = withFrame
		
		containerView.customCornerRadius = 8
		containerView.maskToBounds = true
		gradient.removeFromSuperlayer()
		gradient = containerView.addGradientPanelRows(withFrame: containerView.bounds)
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
