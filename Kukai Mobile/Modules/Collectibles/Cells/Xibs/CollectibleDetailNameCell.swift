//
//  CollectibleDetailNameCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailNameCell: UICollectionViewCell {

	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var websiteImageView: UIImageView!
	@IBOutlet weak var websiteButton: UIButton!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
