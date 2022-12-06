//
//  TokenDetailsStakingRewardsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

class TokenDetailsStakingRewardsCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	
	@IBOutlet weak var lastBakerIcon: UIImageView!
	@IBOutlet weak var lastBaker: UILabel!
	@IBOutlet weak var lastAmount: UILabel!
	@IBOutlet weak var lastTime: UILabel!
	@IBOutlet weak var lastCycle: UILabel!
	
	@IBOutlet weak var nextBakerIcon: UIImageView!
	@IBOutlet weak var nextBaker: UILabel!
	@IBOutlet weak var nextAmount: UILabel!
	@IBOutlet weak var nextTime: UILabel!
	@IBOutlet weak var nextCycle: UILabel!
	
	func setup() {
		
	}
	
	@IBAction func infoTapped(_ sender: Any) {
	}
}
