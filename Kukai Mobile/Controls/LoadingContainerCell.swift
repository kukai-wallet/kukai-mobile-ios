//
//  LoadingContainerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/04/2023.
//

import UIKit
import Combine

public struct LoadingContainerCellObject: Hashable {
	let id = UUID()
}

class LoadingContainerCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconShimmerView: ShimmerView!
	@IBOutlet var shimmerViews: [ShimmerView]!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	public func setup() {
		iconShimmerView.startAnimating()
		for view in shimmerViews {
			view.startAnimating()
		}
	}
}
