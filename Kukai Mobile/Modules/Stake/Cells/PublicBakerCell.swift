//
//  PublicBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class PublicBakerCell: UITableViewCell {
	
	@IBOutlet weak var bakerIcon: SDAnimatedImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	
	@IBOutlet weak var delegationSplit: UILabel!
	@IBOutlet weak var delegationAPY: UILabel!
	@IBOutlet weak var delegationFreeSpace: UILabel!
	
	@IBOutlet weak var stakingSplit: UILabel!
	@IBOutlet weak var stakingAPY: UILabel!
	@IBOutlet weak var stakingFreeSpace: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		GradientView.add(toView: contentView, withType: .tableViewCell)
	}
	
	public func setup(withBaker baker: TzKTBaker) {
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		
		if baker.delegation.enabled {
			delegationSplit.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationAPY.text = Decimal((baker.delegation.estimatedApy * 100)).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationFreeSpace.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.delegation.freeSpace, decimalPlaces: 0, includeThousand: true, allowNegative: true)
			
			if baker.delegation.freeSpace < .zero {
				delegationFreeSpace.textColor = .colorNamed("TxtAlert4")
			} else {
				delegationFreeSpace.textColor = .colorNamed("Txt8")
			}
		} else {
			delegationSplit.text = "N/A"
			delegationAPY.text = "N/A"
			delegationFreeSpace.text = "N/A"
		}
		
		if baker.staking.enabled {
			stakingSplit.text = (Decimal(baker.staking.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			stakingAPY.text = Decimal((baker.staking.estimatedApy * 100)).rounded(scale: 2, roundingMode: .bankers).description + "%"
			stakingFreeSpace.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.staking.freeSpace, decimalPlaces: 0, includeThousand: true, allowNegative: true)
			
			if baker.staking.freeSpace < .zero {
				stakingFreeSpace.textColor = .colorNamed("TxtAlert4")
			} else {
				stakingFreeSpace.textColor = .colorNamed("Txt8")
			}
		} else {
			stakingSplit.text = "N/A"
			stakingAPY.text = "N/A"
			stakingFreeSpace.text = "N/A"
		}
		
		bakerNameLabel.accessibilityIdentifier = "baker-list-name"
	}
	
	override func prepareForReuse() {
		bakerIcon.sd_cancelCurrentImageLoad()
		bakerIcon = nil
	}
}
