//
//  FavouriteTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class FavouriteTokenCell: UITableViewCell {
	
	@IBOutlet weak var favIcon: UIImageView!
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
	
	func setFav(_ isFav: Bool) {
		if isFav {
			favIcon.image = UIImage(named: "star-fill")
			
		} else {
			favIcon.image = UIImage(named: "star-no-fill")
		}
	}
}