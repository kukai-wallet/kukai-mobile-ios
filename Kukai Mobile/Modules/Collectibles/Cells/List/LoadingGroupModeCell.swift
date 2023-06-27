//
//  LoadingGroupModeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/06/2023.
//

import UIKit
import Combine

class LoadingGroupModeCell: UICollectionViewCell {

	@IBOutlet var shimmerViews: [ShimmerView]!
	
	private var gradientLayer: CAGradientLayer? = nil
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
					
				}.store(in: &bag)
		}
		
		for view in shimmerViews {
			view.startAnimating()
		}
	}
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
	}
}
