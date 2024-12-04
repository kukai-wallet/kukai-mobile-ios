//
//  TokenDetailsBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/11/2024.
//

import UIKit
import KukaiCoreSwift

protocol TokenDetailsBakerDelegate: AnyObject {
	func changeTapped()
	func learnTapped()
}

class TokenDetailsBakerCell: UITableViewCell {

	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerLabel: UILabel!
	@IBOutlet weak var bakerApyLabel: UILabel!
	@IBOutlet weak var regularlyVotesTitle: UILabel!
	@IBOutlet weak var regularlyVotesIcon: UIImageView!
	@IBOutlet weak var freeSpaceTitleLabel: UILabel!
	@IBOutlet weak var freeSpaceValueLabel: UILabel!
	
	@IBOutlet weak var bakerButton: CustomisableButton!
	@IBOutlet weak var learnButton: CustomisableButton!
	
	public weak var delegate: TokenDetailsBakerDelegate? = nil
	
	func setup(data: TokenDetailsBakerData) {
		
		bakerButton.customButtonType = .tertiary
		learnButton.customButtonType = .secondary
		bakerButton.isEnabled = !data.bakerChangeDisabled
		
		if let bakerName = data.bakerName {
			
			// If we have baker data
			MediaProxyService.load(url: data.bakerIcon, to: bakerIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
			
			bakerButton.setTitle("Change Baker", for: .normal)
			regularlyVotesTitle.isHidden = false
			regularlyVotesIcon.isHidden = false
			freeSpaceTitleLabel.isHidden = false
			freeSpaceValueLabel.isHidden = false
			
			bakerLabel.text = bakerName
			bakerApyLabel.text = "Est APY: \(data.bakerApy.rounded(scale: 2, roundingMode: .bankers))%"
			
			
			let filterTrueVotes = data.votingParticipation.filter { $0 }
			if filterTrueVotes.count == 5 {
				regularlyVotesIcon.image = UIImage.init(named: "Check")
				regularlyVotesIcon.tintColor = .colorNamed("BGGood4")
				
			} else if filterTrueVotes.count >= 3 {
				regularlyVotesIcon.image = UIImage.init(named: "AlertKnockout")
				regularlyVotesIcon.tintColor = .colorNamed("TxtB-alt4")
				
			} else {
				regularlyVotesIcon.image = UIImage.init(named: "Close")
				regularlyVotesIcon.tintColor = .colorNamed("TxtAlert4")
			}
			
			
			freeSpaceValueLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(data.freeSpace, decimalPlaces: 6, includeThousand: true, allowNegative: true, maximumFractionDigits: 0)
			if data.freeSpace > 0 && data.enoughSpaceForBalance {
				freeSpaceTitleLabel.textColor = .colorNamed("Txt10")
				freeSpaceValueLabel.textColor = .colorNamed("Txt8")
			} else {
				freeSpaceTitleLabel.textColor = .colorNamed("TxtAlert4")
				freeSpaceValueLabel.textColor = .colorNamed("TxtAlert4")
			}
		} else {
			
			// Else show new user style info
			bakerIcon.image = UIImage(named: "AlertKnockout")
			bakerIcon.tintColor = .colorNamed("BGB4")
			
			bakerButton.setTitle("Start Staking", for: .normal)
			regularlyVotesTitle.isHidden = true
			regularlyVotesIcon.isHidden = true
			freeSpaceTitleLabel.isHidden = true
			freeSpaceValueLabel.isHidden = true
			
			bakerLabel.text = "No baker chosen"
			bakerLabel.textColor = .colorNamed("Txt2")
			bakerApyLabel.text = "Delegate and stake your XYZ to participate in on chain governance and earn interest."
			bakerApyLabel.textColor = .colorNamed("Txt8")
		}
		
	}
	
	@IBAction func changeTapped(_ sender: UIButton) {
		self.delegate?.changeTapped()
	}
	
	@IBAction func learnTapped(_ sender: UIButton) {
		self.delegate?.learnTapped()
	}
}
