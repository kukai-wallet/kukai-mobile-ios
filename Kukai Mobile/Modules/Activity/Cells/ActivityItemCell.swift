//
//  ActivityItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class ActivityItemCell: UITableViewCell, UITableViewCellContainerView {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	
	@IBOutlet weak var typeIcon: UIImageView!
	@IBOutlet weak var typeIconStackView: UIStackView!
	@IBOutlet weak var typeLabel: UILabel!
	@IBOutlet weak var ellipsesImage: UIImageView!
	@IBOutlet weak var chevronImage: UIImageView!
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	
	@IBOutlet weak var destinationStackView: UIStackView!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var destinationIconStackView: UIStackView!
	@IBOutlet weak var destinationIcon: UIImageView!
	@IBOutlet weak var destinationLabel: UILabel!
	
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var invisibleRightButton: UIButton!
	
	private static let sendTitleColor = UIColor.colorNamed("Txt10")
	private static let receiveTitleColor = UIColor.colorNamed("TxtB6")
	private static let contractTitleColor = UIColor.colorNamed("Txt2")
	
	var gradientLayer = CAGradientLayer()
	
	
	func setup(data: TzKTTransactionGroup) {
		hasTime(true)
		
		let timeSinceNow = (data.transactions[0].date ?? Date()).timeIntervalSince(Date())
		
		// Status
		if timeSinceNow > -60 && data.transactions.first?.status != .unconfirmed {
			timeLabel.textColor = .colorNamed("TxtGood4")
			timeLabel.text = "CONFIRMED"
			
		} else {
			timeLabel.textColor = .colorNamed("Txt12")
			
			if data.transactions.first?.status == .unconfirmed {
				timeLabel.text = "UNCONFIRMED"
			} else {
				
				timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
			}
		}
		
		
		// Type
		if data.transactions.count > 1 {
			hasChildren(true)
			hasType(false)
			hasDestinationImage(false)
			
			iconView.image = UIImage(named: "BatchKnockout")
			typeLabel.textColor = ActivityItemCell.contractTitleColor
			typeLabel.text = batchString(from: data)
			
			if let appName = data.transactions[0].target?.alias {
				toLabel.text = "App:"
				destinationLabel.text = appName
				
			} else {
				toLabel.isHidden = true
				destinationLabel.text = data.transactions[0].target?.address.truncateTezosAddress() ?? ""
			}
			
		} else if data.groupType == .contractCall {
			hasChildren(false)
			hasType(false)
			hasDestinationImage(false)
			
			iconView.image = UIImage(named: "CallKnockOut")
			typeLabel.textColor = ActivityItemCell.contractTitleColor
			typeLabel.text = "Call: \(data.entrypointCalled ?? "Unknown")"
			
			if let appName = data.transactions[0].target?.alias {
				toLabel.text = "App:"
				destinationLabel.text = appName
				
			} else {
				toLabel.isHidden = true
				destinationLabel.text = data.transactions[0].target?.address ?? ""
			}
			
		} else if data.groupType == .send || data.groupType == .receive {
			hasChildren(false)
			hasType(true)
			
			let titleText = titleAndSubtitle(forToken: data.primaryToken)
			titleLabel.text = titleText.title
			
			if let subTitle = titleText.subtitle {
				subTitleLabel.text = subTitle
				iconView.customCornerRadius = 6
			} else {
				subTitleLabel.isHidden = true
				iconView.customCornerRadius = 16
			}
			
			iconView.addTokenIcon(token: data.primaryToken)
			destinationIconStackView.isHidden = true
			destinationLabel.text = destinationFrom(data)
			
			if data.groupType == .send {
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
	
	func setup(data: TzKTTransaction) {
		hasTime(false)
		hasChildren(false)
		
		if data.subType == .contractCall {
			hasType(false)
			hasDestinationImage(false)
			
			iconView.image = UIImage(named: "CallKnockOut")
			typeLabel.textColor = ActivityItemCell.contractTitleColor
			typeLabel.text = "Call: \(data.entrypointCalled ?? "Unknown")"
			
			if let appName = data.target?.alias {
				toLabel.text = "App:"
				destinationLabel.text = appName
				
			} else {
				toLabel.isHidden = true
				destinationLabel.text = data.target?.address ?? ""
			}
			
		} else if data.subType == .reveal {
			hasType(false)
			hasDestinationImage(false)
			
			iconView.image = UIImage(named: "CallKnockOut")
			typeLabel.textColor = ActivityItemCell.contractTitleColor
			typeLabel.text = "Reveal public key"
			
			toLabel.isHidden = true
			destinationLabel.isHidden = true
			
		} else if data.subType == .send || data.subType == .receive {
			hasType(true)
			
			let titleText = titleAndSubtitle(forToken: data.primaryToken)
			titleLabel.text = titleText.title
			
			if let subTitle = titleText.subtitle {
				subTitleLabel.text = subTitle
				iconView.customCornerRadius = 6
			} else {
				subTitleLabel.isHidden = true
				iconView.customCornerRadius = 16
			} 
			
			iconView.addTokenIcon(token: data.primaryToken)
			subTitleLabel.isHidden = true
			destinationIconStackView.isHidden = true
			
			if data.subType == .send {
				typeIcon.image = .init(named: "ArrowSend")
				typeIcon.tintColor = ActivityItemCell.sendTitleColor
				typeLabel.text = "Send"
				typeLabel.textColor = ActivityItemCell.sendTitleColor
				toLabel.text = "To: "
				destinationLabel.text = data.target?.alias ?? data.target?.address.truncateTezosAddress()
				
			} else {
				typeIcon.image = .init(named: "ArrowReceive")
				typeIcon.tintColor = ActivityItemCell.receiveTitleColor
				typeLabel.text = "Receive"
				typeLabel.textColor = ActivityItemCell.receiveTitleColor
				toLabel.text = "From: "
				destinationLabel.text = data.sender.alias ?? data.sender.address.truncateTezosAddress()
			}
		}
	}
	
	
	// MARK: - UI Helpers
	
	private func hasChildren(_ value: Bool) {
		if value {
			chevronImage.isHidden = false
			ellipsesImage.isHidden = true
			invisibleRightButton.isHidden = true
			
		} else {
			chevronImage.isHidden = true
			ellipsesImage.isHidden = false
			invisibleRightButton.isHidden = false
		}
	}
	
	private func hasType(_ value: Bool) {
		if value {
			typeIconStackView.isHidden = false
			titleLabel.isHidden = false
			subTitleLabel.isHidden = false
			
		} else {
			typeIconStackView.isHidden = true
			titleLabel.isHidden = true
			subTitleLabel.isHidden = true
		}
	}
	
	private func isNFT(_ value: Bool) {
		if value {
			subTitleLabel.isHidden = false
		} else {
			subTitleLabel.isHidden = true
		}
	}
	
	private func hasTime(_ value: Bool) {
		if value {
			timeLabel.isHidden = false
		} else {
			timeLabel.isHidden = true
		}
	}
	
	private func hasDestinationImage(_ value: Bool) {
		if value {
			destinationIconStackView.isHidden = false
		} else {
			destinationIconStackView.isHidden = true
		}
	}
	
	private func batchString(from group: TzKTTransactionGroup) -> String {
		var initialString = "Batch (\(group.transactions.count))"
		
		if group.groupType == .exchange, let primaryToken = group.primaryToken, let secondaryToken = group.secondaryToken {
			initialString += " - Swap \(primaryToken.symbol) for \(secondaryToken.symbol)"
			
		} else if group.groupType == .send, let primaryToken = group.primaryToken {
			initialString += " - Send \(primaryToken.balance.normalisedRepresentation) \(primaryToken.symbol)"
			
		} else if group.groupType == .receive, let primaryToken = group.primaryToken {
			initialString += " - Receive \(primaryToken.balance.normalisedRepresentation) \(primaryToken.symbol)"
			
		} else if group.groupType == .contractCall {
			initialString += " - Call: \(group.entrypointCalled ?? "Unknown")"
		}
		
		return initialString
	}
	
	private func destinationFrom(_ group: TzKTTransactionGroup) -> String {
		if group.groupType == .send {
			return group.transactions[0].target?.alias ?? group.transactions[0].target?.address.truncateTezosAddress() ?? ""
		} else {
			return group.transactions[0].sender.alias ?? group.transactions[0].sender.address.truncateTezosAddress()
		}
	}
	
	private func titleAndSubtitle(forToken token: Token?) -> (title: String, subtitle: String?) {
		guard let token = token else {
			return (title: "Unknown Token", subtitle: nil)
		}
		
		if token.tokenType == .nonfungible {
			return (title: "(\(token.balance.normalisedRepresentation)) \(token.name ?? "")",
					subtitle: token.symbol == "" ? nil : token.symbol)
			
		} else {
			return (title: "\(token.balance.normalisedRepresentation) \(token.symbol)", subtitle: nil)
		}
	}
	 
	public func setOpen() {
		gradientLayer.opacity = 0
		backgroundColor = .colorNamed("BGActivityBatch")
		chevronImage.rotate(degrees: 90, duration: 0.3)
	}
	
	public func setClosed() {
		gradientLayer.opacity = 1
		backgroundColor = .clear
		chevronImage.rotateBack(duration: 0.3)
	}
	
	
	
	// MARK: - actions
	
	@IBAction func invisibleRIghtButtonTapped(_ sender: Any) {
		
	}
}
