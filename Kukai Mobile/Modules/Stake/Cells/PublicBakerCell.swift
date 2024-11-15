//
//  PublicBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class PublicBakerCell: UITableViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var bakerIcon: SDAnimatedImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var splitLabel: UILabel!
	@IBOutlet weak var spaceLabel: UILabel!
	@IBOutlet weak var estRewardsLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		GradientView.add(toView: contentView, withType: .tableViewCell)
	}
	
	public func setup(withBaker baker: TzKTBaker) {
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		splitLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
		spaceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.delegation.freeSpace, decimalPlaces: 0) + " XTZ"
		estRewardsLabel.text = Decimal((baker.delegation.estimatedApy * 100)).rounded(scale: 2, roundingMode: .bankers).description + "%"
		
		bakerNameLabel.accessibilityIdentifier = "baker-list-name"
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [bakerIcon]
	}
}
