//
//  CollectibleDetailAttributeHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailAttributeHeaderCell: UICollectionViewCell {

	@IBOutlet weak var chevronImage: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	public func setOpen() {
		chevronImage.rotateBack(duration: 0.3)
	}
	
	public func setClosed() {
		chevronImage.rotate(degrees: 180, duration: 0.3)
	}
}
