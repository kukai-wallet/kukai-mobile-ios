//
//  PublicBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class PublicBakerCell: UITableViewCell, UITableViewCellContainerView, UITableViewCellImageDownloading {
	
	@IBOutlet weak var bakerIcon: SDAnimatedImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var splitLabel: UILabel!
	@IBOutlet weak var spaceLabel: UILabel!
	@IBOutlet weak var estRewardsLabel: UILabel!
	@IBOutlet weak var containerView: UIView!
	
	var gradientLayer = CAGradientLayer()
	
	public func setup(withBaker baker: TzKTBaker) {
		MediaProxyService.load(url: URL(string: baker.logo ?? ""), to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		splitLabel.text = (Decimal(baker.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
		spaceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.freeSpace, decimalPlaces: 0) + " tez"
		estRewardsLabel.text = (baker.estimatedRoi * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
		
		bakerNameLabel.accessibilityIdentifier = "baker-list-name"
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [bakerIcon]
	}
}
