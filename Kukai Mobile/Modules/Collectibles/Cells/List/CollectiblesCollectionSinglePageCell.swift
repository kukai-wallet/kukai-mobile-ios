//
//  CollectiblesCollectionSinglePageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 10/05/2023.
//

import UIKit
import SDWebImage

class CollectiblesCollectionSinglePageCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var buttonView: UIView!
	@IBOutlet var mediaIconView: UIImageView!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	private var gradient = CAGradientLayer()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		buttonView.accessibilityTraits = .button
		gradient = buttonView.addGradientButtonPrimary(withFrame: buttonView.bounds)
	}
	
	func setupViews(quantity: String?, isRichMedia: Bool) {
		if let quantity = quantity {
			quantityView.isHidden = false
			quantityLabel.text = quantity
			
		} else {
			quantityView.isHidden = true
		}
		
		if isRichMedia {
			mediaIconView.isHidden = false
		} else {
			mediaIconView.isHidden = true
		}
		
		iconView.accessibilityIdentifier = "collecibtles-single-page-icon"
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
