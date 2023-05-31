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
	@IBOutlet weak var typeLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var destinationIconStackView: UIStackView!
	@IBOutlet weak var destinationIcon: UIImageView!
	@IBOutlet weak var destinationLabel: UILabel!
	
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var invisibleRightButton: UIButton!
	
	private static let sendTitleColor = UIColor.colorNamed("Txt10")
	private static let receiveTitleColor = UIColor.colorNamed("TxtB6")
	
	var gradientLayer = CAGradientLayer()
	
	
	func setup(data: TzKTTransactionGroup) {
		if let tx = data.transactions.first {
			setup(data: tx)
		}
	}
	
	func setup(data: TzKTTransaction) {
		
		// Time or confirmed
		let timeSinceNow = (data.date ?? Date()).timeIntervalSince(Date())
		if timeSinceNow > -60 && data.status != .unconfirmed {
			hasTime(false)
		} else {
			hasTime(true)
			timeLabel.text = data.date?.timeAgoDisplay() ?? ""
		}
		
		// Icon and title
		iconView.addTokenIcon(token: data.primaryToken)
		titleLabel.text = title(forToken: data.primaryToken)
		
		if data.primaryToken?.tokenType == .nonfungible {
			iconView.customCornerRadius = 8
		} else {
			iconView.customCornerRadius = 20
		}
		
		// Destination
		destinationIconStackView.isHidden = true
		destinationLabel.text = destinationFrom(data)
		
		
		// Send or receive differences
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
	
	
	// MARK: - UI Helpers
	
	private func hasTime(_ value: Bool) {
		if value {
			timeLabel.isHidden = false
			confirmedLabel.isHidden = true
			confirmedIcon.isHidden = true
			
		} else {
			timeLabel.isHidden = true
			confirmedLabel.isHidden = false
			confirmedIcon.isHidden = false
		}
	}
	
	private func title(forToken token: Token?) -> String {
		guard let token = token else {
			return "Unknown Token"
		}
		
		if token.tokenType == .nonfungible {
			return "(\(token.balance.normalisedRepresentation)) \(token.name ?? "")"
			
		} else {
			return "\(token.balance.normalisedRepresentation) \(token.symbol)"
		}
	}
	
	private func destinationFrom(_ tx: TzKTTransaction) -> String {
		if tx.subType == .send {
			return tx.target?.alias ?? tx.target?.address.truncateTezosAddress() ?? ""
		} else {
			return tx.sender.alias ?? tx.sender.address.truncateTezosAddress()
		}
	}
}
