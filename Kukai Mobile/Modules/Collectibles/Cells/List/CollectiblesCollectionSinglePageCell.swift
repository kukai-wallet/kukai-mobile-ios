//
//  CollectiblesCollectionSinglePageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 10/05/2023.
//

import UIKit

class CollectiblesCollectionSinglePageCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var buttonView: UIView!
	
	private var gradient = CAGradientLayer()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = buttonView.addGradientButtonPrimary(withFrame: buttonView.bounds)
	}
}
