//
//  AccountDiscoverCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/08/2023.
//

import UIKit
import KukaiCoreSwift

class AccountDiscoverCell: UITableViewCell {

	@IBOutlet weak var image1: UIImageView!
	@IBOutlet weak var image2: UIImageView!
	@IBOutlet weak var image3: UIImageView!
	@IBOutlet weak var image4: UIImageView!
	@IBOutlet weak var image5: UIImageView!
	@IBOutlet weak var image6: UIImageView!
	
	func setup() {
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/dogami-thumbnail/raw"), to: image1, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 21, height: 21))
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/gap_600x600/raw"), to: image2, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 33, height: 33))
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/mclaren-thumbnail2/raw"), to: image3, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 44, height: 44))
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/mufc/raw"), to: image4, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 44, height: 44))
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/ziggurats/raw"), to: image5, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 33, height: 33))
		MediaProxyService.load(url: URL(string: "https://imagedelivery.net/X6w5bi3ztwg4T4f6LG8s0Q/assets/img/alias/mooncakes/raw"), to: image6, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 21, height: 21))
	}
}
