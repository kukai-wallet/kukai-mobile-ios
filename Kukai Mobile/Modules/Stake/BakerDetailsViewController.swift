//
//  BakerDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift

class BakerDetailsViewController: UIViewController {
	
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var splitLabel: UILabel!
	@IBOutlet weak var spaceLabel: UILabel!
	@IBOutlet weak var rewardslabel: UILabel!
	@IBOutlet weak var freeLabel: UILabel!
	
	@IBOutlet weak var stakeButton: CustomisableButton!
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		stakeButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let baker = TransactionService.shared.delegateData.chosenBaker else {
			return
		}
		
		stakeButton.isHidden = DependencyManager.shared.balanceService.account.delegate?.address == baker.address
		
		MediaProxyService.load(url: baker.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		splitLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
		spaceLabel.text = baker.delegation.capacity.rounded(scale: 0, roundingMode: .bankers).description + " XTZ"
		rewardslabel.text = Decimal(baker.delegation.estimatedApy * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
		freeLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.delegation.freeSpace, decimalPlaces: 0) + " XTZ"
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func stakeTapped(_ sender: Any) {
		let parent = ((self.presentationController?.presentingViewController as? UINavigationController)?.viewControllers.last as? StakeViewController)
		parent?.stakeTapped()
		self.dismissBottomSheet()
	}
}

extension BakerDetailsViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		view.setNeedsLayout()
		view.layoutIfNeeded()
		
		return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
	}
}
