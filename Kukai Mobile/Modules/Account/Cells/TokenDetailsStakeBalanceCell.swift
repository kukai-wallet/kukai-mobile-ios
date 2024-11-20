//
//  TokenDetailsStakeBalanceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/11/2024.
//

import UIKit

protocol TokenDetailsStakeBalanceDelegate: AnyObject {
	func stakeTapped()
	func unstakeTapped()
	func finalizeTapped()
}

class TokenDetailsStakeBalanceCell: UITableViewCell {

	@IBOutlet weak var stakedBalanceLabel: UILabel!
	@IBOutlet weak var stakedValueLabel: UILabel!
	
	@IBOutlet weak var finalizeBalanceLabel: UILabel!
	@IBOutlet weak var finalizeValueLabel: UILabel!
	
	@IBOutlet weak var stakeButton: CustomisableButton!
	@IBOutlet weak var unstakeButton: CustomisableButton!
	@IBOutlet weak var finalizeButton: CustomisableButton!
	
	public weak var delegate: TokenDetailsStakeBalanceDelegate? = nil
	
	func setup(data: TokenDetailsStakeData) {
		
		stakeButton.customButtonType = .secondary
		unstakeButton.customButtonType = .secondary
		finalizeButton.customButtonType = .secondary
		
		stakedBalanceLabel.text = data.stakedBalance
		stakedValueLabel.text = data.stakedValue
		finalizeBalanceLabel.text = data.finalizeBalance
		finalizeValueLabel.text = data.finalizeValue
		
		stakeButton.isEnabled = !data.buttonsDisabled && data.canStake
		unstakeButton.isEnabled = !data.buttonsDisabled && data.canUnstake
		finalizeButton.isEnabled = !data.buttonsDisabled && data.canFinalize
	}
	
	@IBAction func stakeTapped(_ sender: Any) {
		self.delegate?.stakeTapped()
	}
	
	@IBAction func unstakeTapped(_ sender: Any) {
		self.delegate?.unstakeTapped()
	}
	
	@IBAction func finalizeTapped(_ sender: Any) {
		self.delegate?.finalizeTapped()
	}
}
