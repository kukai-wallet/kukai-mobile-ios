//
//  TokenDetailsHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/11/2023.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsHeaderCell: UITableViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var priceChangeArrow: UIImageView!
	@IBOutlet weak var priceChangeLabel: UILabel!
	@IBOutlet weak var priceChangeDate: UILabel!
	
	
	func setup(data: TokenDetailsHeaderData) {
		priceChangeDate.accessibilityIdentifier = "token-details-selected-date"
		
		if let url = data.tokenURL {
			MediaProxyService.load(url: url, to: iconView, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
		} else {
			iconView.image = data.tokenImage
		}
		
		symbolLabel.text = data.tokenName
		fiatLabel.text = data.fiatAmount
		
		priceChangeArrow.isHidden = true
		priceChangeLabel.text = ""
		priceChangeDate.text = ""
	}
	
	func changePriceDisplay(data: TokenDetailsHeaderData) {
		fiatLabel.text = data.fiatAmount
		
		guard data.priceChangeText != "" else {
			return
		}
		
		priceChangeArrow.isHidden = false
		priceChangeLabel.text = data.priceChangeText
		priceChangeDate.text = data.priceRange
		
		if data.isPriceChangePositive {
			let color = UIColor.colorNamed("TxtGood4")
			var image = UIImage(named: "ArrowUp")
			image = image?.resizedImage(size: CGSize(width: 12, height: 12))
			image = image?.withTintColor(color)
			
			priceChangeArrow.image = image
			priceChangeLabel.textColor = color
			
		} else {
			let color = UIColor.colorNamed("TxtAlert4")
			var image = UIImage(named: "ArrowDown")
			image = image?.resizedImage(size: CGSize(width: 12, height: 12))
			image = image?.withTintColor(color)
			
			priceChangeArrow.image = image
			priceChangeLabel.textColor = color
		}
	}
}
