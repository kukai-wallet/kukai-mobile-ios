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
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/0"), to: image1, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 21, height: 21))
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/1"), to: image2, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 33, height: 33))
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/2"), to: image3, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 44, height: 44))
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/3"), to: image4, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 44, height: 44))
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/4"), to: image5, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 33, height: 33))
		MediaProxyService.load(url: URL(string: "https://services.kukai.app/v4/onboarding/discover/assets/5"), to: image6, withCacheType: .temporary, fallback: UIImage.unknownToken(),
							   downSampleSize: CGSize.screenScaleAwareSize(width: 21, height: 21))
	}
}
