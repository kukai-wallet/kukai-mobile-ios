//
//  FavouriteTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class FavouriteTokenCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var favIcon: UIImageView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var containerView: UIView!
	
	var gradientLayer = CAGradientLayer()
	private var myReorderImage: UIImage? = nil
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	func setFav(_ isFav: Bool) {
		if isFav {
			favIcon.image = UIImage(named: "star-fill")
			
		} else {
			favIcon.image = UIImage(named: "star-no-fill")
		}
	}
}
