//
//  TokenDetailsStakingRewardsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsStakingRewardsCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	
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
	
	private var gradient = CAGradientLayer()
	
	func setup(data: AggregateRewardInformation) {
		if let previousReward = data.previousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: lastBakerIcon.frame.size)
			
			lastBaker.text = previousReward.bakerAlias
			lastAmountTitle.text = "Amount (fee)"
			lastAmount.text = previousReward.amount.normalisedRepresentation + " (\(previousReward.fee * 100)%)"
			lastTimeTitle.text = "Time"
			lastTime.text = previousReward.timeString
			lastCycleTitle.text = "Cycle"
			lastCycle.text = previousReward.cycle.description
			
		} else if let previousReward = data.estimatedPreviousReward {
			MediaProxyService.load(url: previousReward.bakerLogo, to: lastBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: lastBakerIcon.frame.size)
			
			lastBaker.text = previousReward.bakerAlias
			lastAmountTitle.text = "Est Amount (fee)"
			lastAmount.text = previousReward.amount.normalisedRepresentation + " (\(previousReward.fee * 100)%)"
			lastTimeTitle.text = "Est Time"
			lastTime.text = previousReward.timeString
			lastCycleTitle.text = "Est Cycle"
			lastCycle.text = previousReward.cycle.description
			
		} else {
			lastBakerIcon.image = UIImage.unknownToken()
			
			lastBaker.text = "N/A"
			lastAmount.text = "N/A"
			lastTime.text = "N/A"
			lastCycle.text = "N/A"
		}
		
		if let nextReward = data.estimatedNextReward {
			MediaProxyService.load(url: nextReward.bakerLogo, to: nextBakerIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: nextBakerIcon.frame.size)
			
			nextBaker.text = nextReward.bakerAlias
			nextAmount.text = nextReward.amount.normalisedRepresentation + " (\(nextReward.fee * 100)%)"
			nextTime.text = nextReward.timeString
			nextCycle.text = nextReward.cycle.description
			
		} else {
			nextBakerIcon.image = UIImage.unknownToken()
			
			nextBaker.text = "N/A"
			nextAmount.text = "N/A"
			nextTime.text = "N/A"
			nextCycle.text = "N/A"
		}
	}
	
	@IBAction func infoTapped(_ sender: Any) {
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = self.containerView.addGradientPanelRows(withFrame: self.containerView.bounds)
	}
}
