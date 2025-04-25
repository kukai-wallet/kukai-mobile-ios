//
//  BakerDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

class BakerDetailsViewController: UIViewController {
	
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
	
	@IBOutlet weak var delegateButton: CustomisableButton!
	
	//private var viewModel = BakerDetailsViewModel()
	//private var cancellable: AnyCancellable?
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		delegateButton.customButtonType = .primary
		
		/*
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success(_):
					let _ = ""
			}
		}
		*/
		
		GradientView.add(toView: infoContainer, withType: .tableViewCell)
		let baker = TransactionService.shared.delegateData.chosenBaker ?? TzKTBaker(address: "", name: "")
		
		if baker.delegation.enabled {
			let freeSpace = baker.delegation.freeSpace
			let capacity = baker.delegation.capacity
			let minBalance = baker.delegation.minBalance
			
			delegationFeeLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationRewardsLabel.text = (Decimal(baker.delegation.estimatedApy) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			delegationFreeLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(freeSpace, decimalPlaces: 0, allowNegative: true)
			delegationCapacityLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(capacity, decimalPlaces: 0, allowNegative: true)
			delegationMinLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(minBalance, decimalPlaces: 0, allowNegative: true)
			
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
			
		} else {
			stakeFeeLabel.text = "N/A"
			stakeRewardsLabel.text = "N/A"
			stakeFreeLabel.text = "N/A"
			stakeCapacityLabel.text = "N/A"
			stakeMinLabel.text = "N/A"
		}
    }
	
	deinit {
		//cancellable?.cancel()
		//viewModel.cleanup()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let baker = TransactionService.shared.delegateData.chosenBaker else {
			return
		}
		
		delegateButton.isHidden = DependencyManager.shared.balanceService.account.delegate?.address == baker.address
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		
		//viewModel.refresh(animate: false)
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
