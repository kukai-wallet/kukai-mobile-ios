//
//  StakePromoCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/04/2025.
//

import UIKit

protocol TokenDetailsStakePromoDelegate: AnyObject {
	func earnTapped()
	func learnTapped()
}

class StakePromoCell: UITableViewCell {
    
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var earningButton: CustomisableButton!
	@IBOutlet weak var learnButton: CustomisableButton!
	
	public weak var delegate: TokenDetailsStakePromoDelegate? = nil
	
	public func setup(isStakeOnly: Bool) {
		if !isStakeOnly {
			titleLabel.text = "Earn Rewards by staking or delegating"
			subtitleLabel.text = "Participate in Tezos governance, improve security."
			earningButton.setTitle("Start Earning", for: .normal)
			
		} else {
			titleLabel.text = "Stake to Earn Higher Rewards"
			subtitleLabel.text = "You are delegating to a baker. Stake XTZ to earn maximum rewards and improve security"
			earningButton.setTitle("Start Staking", for: .normal)
		}
		
		earningButton.customButtonType = .secondary
	}
	
	@IBAction func earningButtonTapped(_ sender: Any) {
		self.delegate?.earnTapped()
	}
	
	@IBAction func learnButtonTapped(_ sender: Any) {
		self.delegate?.learnTapped()
	}
}
