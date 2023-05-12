//
//  CollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift

protocol CollectiblesViewControllerChild {
	var delegate: UIViewController? { get set }
	
	func needsRefreshFromParent()
}

class CollectiblesViewController: UIViewController {

	@IBOutlet weak var ghostnetStackview: UIStackView!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var containerView: UIView!
	
	private var pageController: OnboardingPageViewController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		segmentedControl.removeBorder()
		segmentedControl.setFonts(selectedFont: .custom(ofType: .medium, andSize: 16), selectedColor: UIColor.colorNamed("Txt8"), defaultFont: UIFont.custom(ofType: .bold, andSize: 16), defaultColor: UIColor.colorNamed("Txt2"))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if DependencyManager.shared.currentNetworkType != .testnet {
			ghostnetStackview.isHidden = true
			
		} else {
			ghostnetStackview.isHidden = false
		}
		
		let isGroupMode = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
		self.segmentedControl.setTitle(isGroupMode ? "Collections" : "All", forSegmentAt: 0)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "pageControl", let page = segue.destination as? OnboardingPageViewController {
			pageController = page
			pageController?.pageDelegate = self
			
		} else if let obj = sender as? (token: Token, image: UIImage?, name: String?), let vc = segue.destination as? CollectionDetailsViewController {
			vc.selectedToken = obj.token
			
			// TODO: remove when we have server
			vc.externalImage = obj.image
			vc.externalName = obj.name
			
		} else if let obj = sender as? NFT {
			TransactionService.shared.sendData.chosenNFT = obj
		}
	}
	
	@IBAction func segmentedControlTapped(_ sender: Any) {
		pageController?.scrollTo(index: segmentedControl.selectedSegmentIndex)
	}
	
	@IBAction func moreButtonTapped(_ sender: UIButton) {
		moreMenu().display(attachedTo: sender)
	}
	
	private func moreMenu() -> MenuViewController {
		let isGroupMode = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
		
		let actionGroup1: [UIAction] = [
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "HiddenOn"), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "hidden", sender: nil)
			})
		]
		
		let actionGroup2: [UIAction] = [
			UIAction(title: isGroupMode ? "Ungroup Collections" : "Group Collections", image: UIImage(named: "LargeIcons"), identifier: nil, handler: { [weak self] action in
				let currentValue = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
				UserDefaults.standard.set(!currentValue, forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
				
				self?.segmentedControl.setTitle(isGroupMode ? "All" : "Collections", forSegmentAt: 0)
				(self?.pageController?.items[0] as? CollectiblesViewControllerChild)?.needsRefreshFromParent()
			})
		]
		
		return MenuViewController(actions: [actionGroup1, actionGroup2], header: nil, sourceViewController: self)
	}
}

extension CollectiblesViewController: OnboardingPageViewControllerDelegate {
	
	func didMove(toIndex index: Int) {
		segmentedControl.selectedSegmentIndex = index
	}
	
	func willMoveToParent() {
		for (index, _) in (pageController?.items ?? []).enumerated() {
			var vc = (pageController?.items[index] as? CollectiblesViewControllerChild)
			vc?.delegate = self
		}
	}
}
