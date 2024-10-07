//
//  ActivityItemContractCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/05/2023.
//

import UIKit
import KukaiCoreSwift

class ActivityItemContractCell: UITableViewCell, ActivityItemCellProcotol {

	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var entrypointLabel: UILabel!
	@IBOutlet weak var destinationLabel: UILabel!
	
	@IBOutlet weak var failedLabel: UILabel!
	@IBOutlet weak var failedIcon: UIImageView!
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	func setup(data: TzKTTransaction) {
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
		
		// Gradient
		if data.status == .unconfirmed {
			containerView.gradientType = .tableViewCellUnconfirmed
			
		} else if data.status == .failed || data.status == .backtracked {
			containerView.gradientType = .tableViewCellFailed
			
		} else {
			containerView.gradientType = .tableViewCell
		}
		
		// Title and destination
		entrypointLabel.text = data.entrypointCalled ?? ""
		destinationLabel.text = data.target?.address.truncateTezosAddress()
	}
	
	func brieflyHideContainer(_ hide: Bool) {
		containerView.isHidden = hide
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
}
