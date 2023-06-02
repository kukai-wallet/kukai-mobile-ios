//
//  ActivityItemContractCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/05/2023.
//

import UIKit
import KukaiCoreSwift

class ActivityItemContractCell: UITableViewCell, UITableViewCellContainerView {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var entrypointLabel: UILabel!
	@IBOutlet weak var destinationLabel: UILabel!
	
	@IBOutlet weak var confirmedLabel: UILabel!
	@IBOutlet weak var confirmedIcon: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	@IBOutlet weak var invisibleRightButton: UIButton!
	
	var gradientLayer = CAGradientLayer()
	
	@IBAction func invisibleRightButtonTapped(_ sender: Any) {
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
		
		// Title and destination
		entrypointLabel.text = data.entrypointCalled ?? ""
		destinationLabel.text = data.target?.address.truncateTezosAddress()
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
}
