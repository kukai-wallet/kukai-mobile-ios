//
//  CollectibleDetailImageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailImageCell: UICollectionViewCell {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var heightConstriant: NSLayoutConstraint!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
