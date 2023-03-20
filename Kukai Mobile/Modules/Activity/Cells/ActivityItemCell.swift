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
	
	
	
	
	/*var color = UIColor.colorNamed("Txt10")
	 var typeimage = UIImage()
	 
	 if data.groupType == .receive {
	 color = UIColor.colorNamed("TxtB6")
	 typeimage = UIImage(named: "ArrowReceive") ?? UIImage.unknownToken()
	 typeimage = typeimage.resizedImage(size: CGSize(width: 10, height: 10)) ?? UIImage.unknownToken()
	 typeimage = typeimage.withTintColor(color)
	 
	 } else {
	 color = UIColor.colorNamed("Txt10")
	 typeimage = UIImage(named: "ArrowSend") ?? UIImage.unknownToken()
	 typeimage = typeimage.resizedImage(size: CGSize(width: 10, height: 10)) ?? UIImage.unknownToken()
	 typeimage = typeimage.withTintColor(color)
	 }
	 
	 
	 transactionTypeIcon.image = typeimage
	 type.text = data.groupType == .send ? "Send" : "Receive"
	 type.textColor = color
	 
	 titleLabel.text = (data.primaryToken?.balance.description ?? "") + " \(data.primaryToken?.symbol ?? "")"
	 toLabel.text = data.groupType == .send ? "To:" : "From:"
	 destinationLabel.text = destinationFrom(data)
	 timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
	 */
	
	
	
	
	
	func setup(data: TzKTTransactionGroup) {
		hasTime(true)
		timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
		
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
				destinationLabel.text = data.transactions[0].target?.address ?? ""
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
			
			iconView.image = UIImage.tezosToken()
			titleLabel.text = "\(data.primaryToken?.balance.normalisedRepresentation ?? "0") \(data.primaryToken?.symbol ?? "")"
			subTitleLabel.isHidden = true
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
			
		} else if data.subType == .send || data.subType == .receive {
			hasType(true)
			
			iconView.image = UIImage.tezosToken()
			titleLabel.text = "\(data.primaryToken?.balance.normalisedRepresentation ?? "0") \(data.primaryToken?.symbol ?? "")"
			subTitleLabel.isHidden = true
			destinationIconStackView.isHidden = true
			
			if data.subType == .send {
				typeIcon.image = .init(named: "ArrowSend")?.withTintColor(ActivityItemCell.sendTitleColor)
				typeLabel.text = "Send"
				typeLabel.textColor = ActivityItemCell.sendTitleColor
				toLabel.text = "To: "
				destinationLabel.text = data.target?.address.truncateTezosAddress()
				
			} else {
				typeIcon.image = .init(named: "ArrowReceive")?.withTintColor(ActivityItemCell.receiveTitleColor)
				typeLabel.text = "Receive"
				typeLabel.textColor = ActivityItemCell.receiveTitleColor
				toLabel.text = "From: "
				destinationLabel.text = data.sender.address.truncateTezosAddress()
			}
		}
	}
	
	
	// MARK: - UI Helpers
	
	/*
	public static func iconFor(_ data: TzKTTransactionGroup) -> UIImage {
		if data.transactions.count > 1 {
			return UIImage(named: "BatchKnockout") ?? UIImage()
			
		} else if data.groupType == .contractCall {
			return UIImage(named: "CallKnockout") ?? UIImage()
			
		} else if data.groupType == .send || data.groupType == .receive {
			return UIImage.tezosToken()
		}
		
		return UIImage.unknownToken()
	}
	
	public static func iconFor(_ data: TzKTTransaction) -> UIImage {
		if data.subType == .contractCall {
			return UIImage(named: "CallKnockout") ?? UIImage()
			
		} else if data.subType == .send || data.subType == .receive {
			return UIImage.tezosToken()
		}
		
		return UIImage.unknownToken()
	}
	*/
	
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
	
	
	
	// MARK: - actions
	
	@IBAction func invisibleRIghtButtonTapped(_ sender: Any) {
		
	}
}
