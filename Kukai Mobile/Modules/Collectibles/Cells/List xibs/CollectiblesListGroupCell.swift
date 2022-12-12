//
//  CollectiblesListGroupCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/12/2022.
//

import UIKit

class CollectiblesListGroupCell: UICollectionViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var countLabel: UILabel!
	
	private var gradientLayer: CAGradientLayer? = nil
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if gradientLayer == nil {
			self.contentView.customCornerRadius = 8
			self.contentView.maskToBounds = true
			gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
		}
	}
}
