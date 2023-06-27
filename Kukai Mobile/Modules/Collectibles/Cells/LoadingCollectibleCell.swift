//
//  LoadingCollectibleCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/06/2023.
//

import UIKit

class LoadingCollectibleCell: UICollectionViewCell {

	@IBOutlet var shimmerViews: [ShimmerView]!
	
	public func setup() {
		for view in shimmerViews {
			view.startAnimating()
		}
	}
}
