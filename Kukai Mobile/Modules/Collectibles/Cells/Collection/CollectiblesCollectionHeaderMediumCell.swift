//
//  CollectiblesCollectionHeaderMediumCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2023.
//

import UIKit

class CollectiblesCollectionHeaderMediumCell: UICollectionViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var creatorLabel: UILabel!
	
	func downloadingImageViews() -> [UIImageView] {
		return [iconView]
	}
}
