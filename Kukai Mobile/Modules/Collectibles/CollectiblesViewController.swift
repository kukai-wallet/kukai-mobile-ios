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
		segmentedControl.setFonts(selectedFont: .custom(ofType: .medium, andSize: 14), selectedColor: UIColor.colorNamed("Txt8"), defaultFont: UIFont.custom(ofType: .bold, andSize: 14), defaultColor: UIColor.colorNamed("Txt2"))
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
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
			
		} else if let obj = sender as? (token: Token, image: UIImage?, name: String?), let vc = segue.destination as? CollectionDetailsViewController {
			vc.selectedToken = obj.token
			
			// TODO: remove when we have server
			vc.externalImage = obj.image
			vc.externalName = obj.name
		}
	}
	
	@IBAction func moreButtonTapped(_ sender: UIButton) {
		moreMenu().display(attachedTo: sender)
	}
	
	private func moreMenu() -> MenuViewController {
		let actions: [UIAction] = [
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "HiddenOn"), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "hidden", sender: nil)
			})
		]
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: self)
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
