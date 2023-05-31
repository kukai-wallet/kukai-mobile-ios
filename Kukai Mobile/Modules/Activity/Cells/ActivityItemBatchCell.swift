//
//  ActivityItemBatchCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/05/2023.
//

import UIKit
import KukaiCoreSwift

class ActivityItemBatchCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var batchCountLabel: UILabel!
	@IBOutlet weak var batchTypeLabel: UILabel!
	@IBOutlet weak var chevronImage: UIImageView!
	@IBOutlet weak var appNameLabel: UILabel!
	
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var invisibleRightButton: UIButton!
	
	var gradientLayer = CAGradientLayer()
	
	@IBAction func invisibleRIghtButton(_ sender: Any) {
	}
	
	func setup(data: TzKTTransactionGroup) {
		
		// Time or confirmed
		let timeSinceNow = (data.transactions[0].date ?? Date()).timeIntervalSince(Date())
		if timeSinceNow > -60 && data.transactions[0].status != .unconfirmed {
			hasTime(false)
		} else {
			hasTime(true)
			timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
		}
		
		// Title and destination
		batchCountLabel.text = "Batch (\(data.transactions.count)"
		batchTypeLabel.text = batchString(from: data)
		appNameLabel.text = data.transactions[0].target?.alias ?? data.transactions[0].target?.address.truncateTezosAddress()
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
	
	private func batchString(from group: TzKTTransactionGroup) -> String {
		var initialString = ""
		
		if group.groupType == .exchange, let primaryToken = group.primaryToken, let secondaryToken = group.secondaryToken {
			initialString = "Swap \(primaryToken.symbol) for \(secondaryToken.symbol)"
			
		} else if group.groupType == .send, let primaryToken = group.primaryToken {
			initialString = "Send \(primaryToken.balance.normalisedRepresentation) \(primaryToken.symbol)"
			
		} else if group.groupType == .receive, let primaryToken = group.primaryToken {
			initialString = "Receive \(primaryToken.balance.normalisedRepresentation) \(primaryToken.symbol)"
			
		} else if group.groupType == .contractCall {
			initialString = "Call: \(group.entrypointCalled ?? "Unknown")"
			
		} else {
			initialString = "Unknown"
		}
		
		return initialString
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
}
