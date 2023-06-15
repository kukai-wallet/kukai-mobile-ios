//
//  CollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

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
	private var bag = [AnyCancellable]()
	private var gradient = CAGradientLayer()
	private var isVisible = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
		segmentedControl.removeBorder()
		segmentedControl.setFonts(selectedFont: .custom(ofType: .medium, andSize: 14), selectedColor: UIColor.colorNamed("Txt8"), defaultFont: UIFont.custom(ofType: .bold, andSize: 14), defaultColor: UIColor.colorNamed("Txt2"))
		
		
		
		DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.isVisible == true && selectedAddress == address {
					self?.displayGhostnet()
				}
			}.store(in: &bag)
		
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				self?.view.setNeedsDisplay()
				
			}.store(in: &bag)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.isVisible = true
		
		displayGhostnet()
		
		let isGroupMode = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
		self.segmentedControl.setTitle(isGroupMode ? "Collections" : "All", forSegmentAt: 0)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.isVisible = false
	}
	
	private func displayGhostnet() {
		if DependencyManager.shared.currentNetworkType != .testnet {
			ghostnetStackview.isHidden = true
			
		} else {
			ghostnetStackview.isHidden = false
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "pageControl", let page = segue.destination as? OnboardingPageViewController {
			pageController = page
			pageController?.pageDelegate = self
			
		} else if let obj = sender as? Token, let vc = segue.destination as? CollectionDetailsViewController {
			vc.selectedToken = obj
			
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
