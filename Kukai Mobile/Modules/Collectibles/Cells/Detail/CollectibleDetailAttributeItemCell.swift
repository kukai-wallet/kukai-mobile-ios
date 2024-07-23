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
	@IBOutlet weak var percentLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		GradientView.add(toView: self.contentView, withType: .collectibleAttributes)
    }
}
