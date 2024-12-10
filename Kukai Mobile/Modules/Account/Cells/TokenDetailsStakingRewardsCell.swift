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
	
	@IBOutlet weak var lastBakerIcon: UIImageView!
	@IBOutlet weak var lastBaker: UILabel!
	@IBOutlet weak var lastDelegationAmountTitle: UILabel!
	@IBOutlet weak var lastDelegationAmount: UILabel!
	@IBOutlet weak var lastStakeAmount: UILabel!
	@IBOutlet weak var lastTimeTitle: UILabel!
	@IBOutlet weak var lastTime: UILabel!
	@IBOutlet weak var lastCycleTitle: UILabel!
	@IBOutlet weak var lastCycle: UILabel!
	
	@IBOutlet weak var nextBakerIcon: UIImageView!
	@IBOutlet weak var nextBaker: UILabel!
	@IBOutlet weak var nextDelegationAmount: UILabel!
	@IBOutlet weak var nextStakeAmount: UILabel!
	@IBOutlet weak var nextTime: UILabel!
	@IBOutlet weak var nextCycle: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup(data: AggregateRewardInformation) {
		
		lastBaker.accessibilityIdentifier = "token-detials-staking-rewards-last-baker"
		nextBaker.accessibilityIdentifier = "token-detials-staking-rewards-next-baker"
		
		if let previousReward = data.previousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let delegationPercentage = Decimal(previousReward.delegateFee * 100).rounded(scale: 2, roundingMode: .bankers)
			let stakingPercentage = Decimal(previousReward.stakeFee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			lastBaker.text = previousReward.bakerAlias
			lastDelegationAmountTitle.text = "Delegation \nAmount (fee)"
			lastDelegationAmount.text = previousReward.delegateAmount.normalisedRepresentation + " (\(delegationPercentage)%)"
			lastStakeAmount.text = previousReward.stakeAmount.normalisedRepresentation + " (\(stakingPercentage)%)"
			lastTimeTitle.text = "Time"
			lastTime.text = previousReward.dateOfPayment.timeAgoDisplay()
			lastCycleTitle.text = "Cycle"
			lastCycle.text = previousReward.cycle == 0 ? "N/A" : previousReward.cycle.description
			
		} else if let previousReward = data.estimatedPreviousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let delegationPercentage = Decimal(previousReward.delegateFee * 100).rounded(scale: 2, roundingMode: .bankers)
			let stakingPercentage = Decimal(previousReward.stakeFee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			lastBaker.text = previousReward.bakerAlias
			lastDelegationAmountTitle.text = "Delegation \nEst Amount (fee)"
			lastDelegationAmount.text = previousReward.delegateAmount.normalisedRepresentation + " (\(delegationPercentage)%)"
			lastStakeAmount.text = previousReward.stakeAmount.normalisedRepresentation + " (\(stakingPercentage)%)"
			lastTimeTitle.text = "Est Time"
			lastTime.text = previousReward.dateOfPayment.timeAgoDisplay()
			lastCycleTitle.text = "Est Cycle"
			lastCycle.text = previousReward.cycle == 0 ? "N/A" : previousReward.cycle.description
			
		} else {
			lastBakerIcon.image = UIImage.unknownToken()
			
			lastBaker.text = "N/A"
			lastDelegationAmount.text = "N/A"
			lastTime.text = "N/A"
			lastCycle.text = "N/A"
		}
		
		if let nextReward = data.estimatedNextReward {
			MediaProxyService.load(url: nextReward.bakerLogo, to: nextBakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			let delegationPercentage = Decimal(nextReward.delegateFee * 100).rounded(scale: 2, roundingMode: .bankers)
			let stakingPercentage = Decimal(nextReward.stakeFee * 100).rounded(scale: 2, roundingMode: .bankers)
			
			nextBaker.text = nextReward.bakerAlias
			nextDelegationAmount.text = nextReward.delegateAmount.normalisedRepresentation + " (\(delegationPercentage)%)"
			nextStakeAmount.text = nextReward.stakeAmount.normalisedRepresentation + " (\(stakingPercentage)%)"
			nextTime.text = nextReward.dateOfPayment.timeAgoDisplay()
			nextCycle.text = nextReward.cycle == 0 ? "N/A" : nextReward.cycle.description
			
		} else {
			nextBakerIcon.image = UIImage.unknownToken()
			
			nextBaker.text = "N/A"
			nextDelegationAmount.text = "N/A"
			nextTime.text = "N/A"
			nextCycle.text = "N/A"
		}
	}
}
