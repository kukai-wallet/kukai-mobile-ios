//
//  CollectibleDetailAttributeItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/10/2022.
//

import UIKit

class CollectibleDetailAttributeItemCell: UICollectionViewCell {

	@IBOutlet weak var keyLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	
	private var gradient = CAGradientLayer()
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = self.contentView.addGradientPanelAttributes(withFrame: self.contentView.bounds)
	}
}
