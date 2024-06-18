//
//  ActivityItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class ActivityItemCell: UITableViewCell, UITableViewCellContainerView, UITableViewCellImageDownloading {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: SDAnimatedImageView!
	
	@IBOutlet weak var typeIcon: UIImageView!
	@IBOutlet weak var typeLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var destinationIconStackView: UIStackView!
	@IBOutlet weak var destinationIcon: UIImageView!
	@IBOutlet weak var destinationLabel: UILabel!
	
	@IBOutlet weak var failedLabel: UILabel!
	@IBOutlet weak var failedIcon: UIImageView!
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	private static let sendTitleColor = UIColor.colorNamed("Txt10")
	private static let receiveTitleColor = UIColor.colorNamed("TxtB6")
	
	var gradientLayer = CAGradientLayer()
	
	func setup(data: TzKTTransactionGroup) {
		if let tx = data.transactions.first {
			setup(data: tx)
		}
	}
	
	func setup(data: TzKTTransaction) {
		iconView.accessibilityIdentifier = "activity-item-icon"
		typeLabel.accessibilityIdentifier = "activity-type-label"
		titleLabel.accessibilityIdentifier = "activity-item-title"
		
		iconView.sd_cancelCurrentImageLoad()
		iconView.image = nil
		
		// Time or confirmed
		let timeSinceNow = (data.date ?? Date()).timeIntervalSince(Date())
		if data.status == .unconfirmed {
			hasTime(true, failed: false)
			timeLabel.text = "UNCONFIRMED"
			
		} else if timeSinceNow > -60 && data.status != .unconfirmed {
			hasTime(false, failed: (data.status == .failed || data.status == .backtracked))
			
		} else {
			hasTime(true, failed: (data.status == .failed || data.status == .backtracked))
			timeLabel.text = data.date?.timeAgoDisplay() ?? ""
		}
		
		if data.subType == .contractCall {
			// Icon and title
			iconView.image = UIImage(named: "CallKnockOut")
			iconView.backgroundColor = .colorNamed("BGThumbNFT")
			iconView.customCornerRadius = 8
			
			typeIcon.isHidden = true
			typeLabel.text = ""
			
			titleLabel.text = "Call: \(data.entrypointCalled ?? "unknown")"
			
			toLabel.isHidden = true
			destinationIconStackView.isHidden = true
			destinationLabel.text = data.target?.alias ?? data.target?.address.truncateTezosAddress()
			
		} else if data.subType == .delegate {
			
			typeIcon.isHidden = true
			typeLabel.text = ""
			toLabel.isHidden = false
			
			if data.newDelegate == nil {
				iconView.image = UIImage.unknownToken()
				iconView.backgroundColor = .white
				iconView.customCornerRadius = 20
				
				titleLabel.text = "Remove Delegate"
				toLabel.text = "From: "
				destinationLabel.text = data.prevDelegate?.alias ?? data.prevDelegate?.address.truncateTezosAddress()
				
			} else {
				let url = TzKTClient.avatarURL(forToken: data.newDelegate?.address ?? "")
				MediaProxyService.load(url: url, to: iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				iconView.backgroundColor = .white
				iconView.customCornerRadius = 20
				
				titleLabel.text = "Delegate"
				toLabel.text = "To: "
				destinationLabel.text = data.newDelegate?.alias ?? data.newDelegate?.address.truncateTezosAddress()
			}
			
			destinationIconStackView.isHidden = true
			
		} else if data.type == .staking {
			typeIcon.isHidden = true
			typeLabel.text = ""
			toLabel.isHidden = false
			
			let url = TzKTClient.avatarURL(forToken: data.baker?.address ?? "")
			MediaProxyService.load(url: url, to: iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
			iconView.backgroundColor = .white
			iconView.customCornerRadius = 20
			
			if data.subType == .stake {
				titleLabel.text = "Stake: \( (data.primaryToken?.balance ?? .zero()).normalisedRepresentation) XTZ"
				toLabel.text = "To: "
				
			} else if data.subType == .unstake {
				titleLabel.text = "Unstake: \( (data.primaryToken?.balance ?? .zero()).normalisedRepresentation) XTZ"
				toLabel.text = "From: "
			}
			
			destinationLabel.text = data.baker?.alias ?? data.baker?.address.truncateTezosAddress() ?? "..."
			destinationIconStackView.isHidden = true
			
		} else {
			
			// Icon and title
			iconView.addTokenIcon(token: data.primaryToken, fallbackToAvatar: false)
			titleLabel.text = title(forToken: data.primaryToken)
			
			if data.primaryToken?.tokenType == .nonfungible {
				iconView.customCornerRadius = 8
			} else {
				iconView.customCornerRadius = 20
			}
			
			// Destination
			destinationFrom(data)
			
			
			// Send or receive differences
			typeIcon.isHidden = false
			toLabel.isHidden = false
			if data.subType == .send {
				typeIcon.image = .init(named: "ArrowSend")
				typeIcon.tintColor = ActivityItemCell.sendTitleColor
				typeLabel.text = "Send"
				typeLabel.textColor = ActivityItemCell.sendTitleColor
				toLabel.text = "To: "
				
			} else {
				typeIcon.image = .init(named: "ArrowReceive")
				typeIcon.tintColor = ActivityItemCell.receiveTitleColor
				typeLabel.text = "Receive"
				typeLabel.textColor = ActivityItemCell.receiveTitleColor
				toLabel.text = "From: "
			}
		}
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
	
	
	// MARK: - UI Helpers
	
	private func hasTime(_ value: Bool, failed: Bool) {
		
		if value && failed {
			timeLabel.isHidden = false
			confirmedLabel.isHidden = true
			confirmedIcon.isHidden = true
			failedLabel.isHidden = false
			failedIcon.isHidden = false
			
		} else if value && !failed {
			timeLabel.isHidden = false
			confirmedLabel.isHidden = true
			confirmedIcon.isHidden = true
			failedLabel.isHidden = true
			failedIcon.isHidden = true
			
		} else if !failed {
			// No time and not failed = confirmed
			timeLabel.isHidden = true
			confirmedLabel.isHidden = false
			confirmedIcon.isHidden = false
			failedLabel.isHidden = true
			failedIcon.isHidden = true
			
		} else {
			// No time and failed = failed
			timeLabel.isHidden = true
			confirmedLabel.isHidden = true
			confirmedIcon.isHidden = true
			failedLabel.isHidden = false
			failedIcon.isHidden = false
		}
	}
	
	private func title(forToken token: Token?) -> String {
		guard let token = token else {
			return "Unknown Token"
		}
		
		if token.tokenType == .nonfungible && (token.balance.toNormalisedDecimal() ?? 0) > 1 {
			return "(\(token.balance.normalisedRepresentation)) \(token.name ?? "Unknwon Token")"
			
		} else if token.tokenType == .nonfungible {
			return token.name ?? "Unknown Token"
			
		} else {
			let symbol = token.symbol == "" ? "Unknown Token" : token.symbol
			return "\(token.balance.normalisedRepresentation) \(symbol)"
		}
	}
	
	private func destinationFrom(_ tx: TzKTTransaction) {
		if tx.subType == .send {
			let record = LookupService.shared.lookupFor(address: tx.target?.address ?? "")
			if record.type == .address {
				destinationIconStackView.isHidden = true
				destinationLabel.text = tx.target?.alias ?? record.displayText.truncateTezosAddress()
				
			} else {
				destinationIconStackView.isHidden = false
				destinationLabel.text = record.displayText
				destinationIcon.image = UIImage(named: record.iconName)
			}
		} else {
			let record = LookupService.shared.lookupFor(address: tx.sender.address)
			if record.type == .address {
				destinationIconStackView.isHidden = true
				destinationLabel.text = tx.sender.alias ?? record.displayText.truncateTezosAddress()
				
			} else {
				destinationIconStackView.isHidden = false
				destinationLabel.text = record.displayText
				destinationIcon.image = UIImage(named: record.iconName)
			}
		}
	}
}
