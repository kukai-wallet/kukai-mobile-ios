//
//  TokenDetailsStakingRewardsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsStakingRewardsCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var infoButton: CustomisableButton!
	
	@IBOutlet weak var lastBakerIcon: UIImageView!
	@IBOutlet weak var lastBaker: UILabel!
	@IBOutlet weak var lastAmountTitle: UILabel!
	@IBOutlet weak var lastAmount: UILabel!
	@IBOutlet weak var lastTimeTitle: UILabel!
	@IBOutlet weak var lastTime: UILabel!
	@IBOutlet weak var lastCycleTitle: UILabel!
	@IBOutlet weak var lastCycle: UILabel!
	
	@IBOutlet weak var nextBakerIcon: UIImageView!
	@IBOutlet weak var nextBaker: UILabel!
	@IBOutlet weak var nextAmount: UILabel!
	@IBOutlet weak var nextTime: UILabel!
	@IBOutlet weak var nextCycle: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup(data: AggregateRewardInformation) {
		
		lastBaker.accessibilityIdentifier = "token-detials-staking=rewards-last-baker"
		nextBaker.accessibilityIdentifier = "token-detials-staking=rewards-next-baker"
		
		if let previousReward = data.previousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let percentage = Decimal(previousReward.fee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			lastBaker.text = previousReward.bakerAlias
			lastAmountTitle.text = "Amount (fee)"
			lastAmount.text = previousReward.amount.normalisedRepresentation + " (\(percentage)%)"
			lastTimeTitle.text = "Time"
			lastTime.text = previousReward.dateOfPayment.timeAgoDisplay()
			lastCycleTitle.text = "Cycle"
			lastCycle.text = previousReward.cycle == 0 ? "N/A" : previousReward.cycle.description
			
		} else if let previousReward = data.estimatedPreviousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let percentage = Decimal(previousReward.fee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			lastBaker.text = previousReward.bakerAlias
			lastAmountTitle.text = "Est Amount (fee)"
			lastAmount.text = previousReward.amount.normalisedRepresentation + " (\(percentage)%)"
			lastTimeTitle.text = "Est Time"
			lastTime.text = previousReward.dateOfPayment.timeAgoDisplay()
			lastCycleTitle.text = "Est Cycle"
			lastCycle.text = previousReward.cycle == 0 ? "N/A" : previousReward.cycle.description
			
		} else {
			lastBakerIcon.image = UIImage.unknownToken()
			
			lastBaker.text = "N/A"
			lastAmount.text = "N/A"
			lastTime.text = "N/A"
			lastCycle.text = "N/A"
		}
		
		if let nextReward = data.estimatedNextReward {
			MediaProxyService.load(url: nextReward.bakerLogo, to: nextBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let percentage = Decimal(nextReward.fee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			nextBaker.text = nextReward.bakerAlias
			nextAmount.text = nextReward.amount.normalisedRepresentation + " (\(percentage)%)"
			nextTime.text = nextReward.dateOfPayment.timeAgoDisplay()
			nextCycle.text = nextReward.cycle == 0 ? "N/A" : nextReward.cycle.description
			
		} else {
			nextBakerIcon.image = UIImage.unknownToken()
			
			nextBaker.text = "N/A"
			nextAmount.text = "N/A"
			nextTime.text = "N/A"
			nextCycle.text = "N/A"
		}
	}
}
