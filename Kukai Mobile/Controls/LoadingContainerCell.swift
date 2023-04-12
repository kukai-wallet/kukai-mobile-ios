//
//  LoadingContainerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/04/2023.
//

import UIKit

public struct LoadingContainerCellObject: Hashable {
	let id = UUID()
}

class LoadingContainerCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet var shimmerViews: [ShimmerView]!
	
	var gradientLayer = CAGradientLayer()
	
	public func setup() {
		for view in shimmerViews {
			//view.setup(color: .colorNamed("BG4"), duration: 1)
			view.startAnimating()
		}
	}
}
