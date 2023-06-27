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

class LoadingContainerCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconShimmerView: ShimmerView!
	@IBOutlet var shimmerViews: [ShimmerView]!
	
	var gradientLayer = CAGradientLayer()
	private var bag: [AnyCancellable] = []
	
	deinit {
		for b in bag {
			b.cancel()
		}
	}
	
	public func setup() {
		
		if bag.count == 0 {
			ThemeManager.shared.$themeDidChange
				.dropFirst()
				.sink { [weak self] _ in
					for view in self?.shimmerViews ?? [] {
						view.reloadForThemeChange()
					}
					
					self?.iconShimmerView.reloadForThemeChange()
					
				}.store(in: &bag)
		}
		
		
		iconShimmerView.startAnimating()
		for view in shimmerViews {
			view.startAnimating()
		}
	}
}
