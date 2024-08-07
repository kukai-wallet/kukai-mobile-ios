//
//  CollectiblesCollectionHeaderMediumCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2023.
//

import UIKit
import SDWebImage

class CollectiblesCollectionHeaderMediumCell: UICollectionViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var creatorLabel: UILabel!
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
