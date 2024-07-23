//
//  LoadingGroupModeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/06/2023.
//

import UIKit

class LoadingGroupModeCell: UICollectionViewCell {

	@IBOutlet var shimmerViews: [ShimmerView]!
	
	public func setup() {
		GradientView.add(toView: self.contentView, withType: .tableViewCell)
		
		for view in shimmerViews {
			view.startAnimating()
		}
	}
}
