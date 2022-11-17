//
//  CollectibleDetailImageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailImageCell: UICollectionViewCell {

	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	@IBOutlet weak var aspectRatioConstraint: NSLayoutConstraint!
	@IBOutlet weak var quantityViewLeadingConstraint: NSLayoutConstraint!
	
	public var setup = false
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
