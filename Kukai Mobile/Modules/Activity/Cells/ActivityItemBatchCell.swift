//
//  ActivityItemBatchCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/05/2023.
//

import UIKit
import KukaiCoreSwift

class ActivityItemBatchCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var batchCountLabel: UILabel!
	@IBOutlet weak var batchTypeLabel: UILabel!
	@IBOutlet weak var chevronImage: UIImageView!
	@IBOutlet weak var appNameLabel: UILabel!
	
	@IBOutlet weak var failedLabel: UILabel!
	@IBOutlet weak var failedIcon: UIImageView!
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var invisibleRightButton: UIButton!
	
	@IBAction func invisibleRIghtButton(_ sender: Any) {
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup(data: TzKTTransactionGroup) {
		// Time or confirmed
		let timeSinceNow = (data.transactions[0].date ?? Date()).timeIntervalSince(Date())
		if data.transactions[0].status == .unconfirmed {
			hasTime(true, failed: false)
			timeLabel.text = "UNCONFIRMED"
			chevronImage.isHidden = true
			containerView.gradientType = .tableViewCellUnconfirmed
			
		} else if timeSinceNow > -60 && data.transactions[0].status != .unconfirmed {
			hasTime(false, failed: (data.status == .failed || data.status == .backtracked))
			chevronImage.isHidden = false
			
		} else {
			hasTime(true, failed: (data.status == .failed || data.status == .backtracked))
			timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
			chevronImage.isHidden = false
		}
		
		
		
		// Title and destination
		batchCountLabel.text = "Batch (\(data.transactions.count)) - "
		batchTypeLabel.text = batchString(from: data)
		appNameLabel.text = data.transactions[0].target?.alias ?? data.transactions[0].target?.address.truncateTezosAddress()
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
		
		if failed {
			containerView.gradientType = .tableViewCellFailed
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
		containerView.setGradientOpaque(true)
		backgroundColor = .colorNamed("BGActivityBatch")
		chevronImage.rotate(degrees: 90, duration: 0.3)
	}
	
	public func setClosed() {
		containerView.setGradientOpaque(false)
		backgroundColor = .clear
		chevronImage.rotateBack(duration: 0.3)
	}
}
