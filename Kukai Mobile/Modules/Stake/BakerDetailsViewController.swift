//
//  BakerDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

class BakerDetailsViewController: UIViewController, BottomSheetCustomFixedProtocol {
	
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	
	@IBOutlet weak var infoContainer: UIView!
	@IBOutlet weak var delegationFeeLabel: UILabel!
	@IBOutlet weak var stakeFeeLabel: UILabel!
	@IBOutlet weak var delegationRewardsLabel: UILabel!
	@IBOutlet weak var stakeRewardsLabel: UILabel!
	@IBOutlet weak var delegationFreeLabel: UILabel!
	@IBOutlet weak var stakeFreeLabel: UILabel!
	@IBOutlet weak var delegationCapacityLabel: UILabel!
	@IBOutlet weak var stakeCapacityLabel: UILabel!
	@IBOutlet weak var delegationMinLabel: UILabel!
	@IBOutlet weak var stakeMinLabel: UILabel!
	
	@IBOutlet weak var changeBakerWarningLabel: UILabel!
	@IBOutlet weak var delegateButton: CustomisableButton!
	
	var dimBackground: Bool = false
	var bottomSheetMaxHeight: CGFloat = 625
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		delegateButton.customButtonType = .primary
		
		
		// Change button based off users action, and ptionally display some staking warning text
		let account = DependencyManager.shared.balanceService.account
		if account.delegate == nil {
			delegateButton.setTitle("Delegate", for: .normal)
			delegateButton.titleLabel?.font = .custom(ofType: .bold, andSize: 20)
		} else {
			delegateButton.setTitle("Change Baker", for: .normal)
			delegateButton.titleLabel?.font = .custom(ofType: .bold, andSize: 20)
		}
		
		if account.xtzStakedBalance > XTZAmount.zero() {
			changeBakerWarningLabel.isHidden = false
		} else {
			changeBakerWarningLabel.isHidden = true
		}
		
		GradientView.add(toView: infoContainer, withType: .tableViewCell)
		let baker = TransactionService.shared.delegateData.chosenBaker ?? TzKTBaker(address: "", name: "")
		let availableBalance = DependencyManager.shared.balanceService.account.availableBalance
		
		if baker.delegation.enabled {
			let freeSpace = baker.delegation.freeSpace
			let capacity = baker.delegation.capacity
			let minBalance = baker.delegation.minBalance
			
			delegationFeeLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationRewardsLabel.text = (Decimal(baker.delegation.estimatedApy) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationFreeLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(freeSpace, decimalPlaces: 0, allowNegative: true)
			delegationCapacityLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(capacity, decimalPlaces: 0, allowNegative: true)
			delegationMinLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(minBalance, decimalPlaces: 0, allowNegative: true)
			
			if freeSpace < (availableBalance.toNormalisedDecimal() ?? freeSpace) {
				delegationFreeLabel.textColor = .colorNamed("TxtAlert4")
			} else {
				delegationFreeLabel.textColor = .colorNamed("Txt8")
			}
			
		} else {
			delegationFeeLabel.text = "N/A"
			delegationRewardsLabel.text = "N/A"
			delegationFreeLabel.text = "N/A"
			delegationCapacityLabel.text = "N/A"
			delegationMinLabel.text = "N/A"
		}
		
		if baker.staking.enabled {
			let freeSpace = baker.staking.freeSpace
			let capacity = baker.staking.capacity
			let minBalance = baker.staking.minBalance
			
			stakeFeeLabel.text = (Decimal(baker.staking.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			stakeRewardsLabel.text = (Decimal(baker.staking.estimatedApy) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			stakeFreeLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(freeSpace, decimalPlaces: 0, allowNegative: true)
			stakeCapacityLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(capacity, decimalPlaces: 0, allowNegative: true)
			stakeMinLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(minBalance, decimalPlaces: 0, allowNegative: true)
			
			if freeSpace < (availableBalance.toNormalisedDecimal() ?? freeSpace) {
				stakeFreeLabel.textColor = .colorNamed("TxtAlert4")
			} else {
				stakeFreeLabel.textColor = .colorNamed("Txt8")
			}
			
		} else {
			stakeFeeLabel.text = "N/A"
			stakeRewardsLabel.text = "N/A"
			stakeFreeLabel.text = "N/A"
			stakeCapacityLabel.text = "N/A"
			stakeMinLabel.text = "N/A"
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let baker = TransactionService.shared.delegateData.chosenBaker else {
			return
		}
		
		delegateButton.isHidden = DependencyManager.shared.balanceService.account.delegate?.address == baker.address
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func delegateTapped(_ sender: Any) {
		let parent = ((self.presentationController?.presentingViewController as? UINavigationController)?.viewControllers.last as? ChooseBakerViewController)
		parent?.delegateTapped()
		self.dismissBottomSheet()
	}
}
