//
//  StakeOnboardingContainerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/11/2024.
//

import UIKit
import KukaiCoreSwift
import Combine

class StakeOnboardingContainerViewController: UIViewController {
	
	@IBOutlet weak var indicatorStackview: UIStackView!
	@IBOutlet weak var indicatorStackviewLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var indicatorStackviewTrailingConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var pageIndicator1: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment1: UIProgressView!
	@IBOutlet weak var pageIndicator2: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment2: UIProgressView!
	@IBOutlet weak var pageIndicator3: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment3: UIProgressView!
	@IBOutlet weak var pageIndicator4: PageIndicatorContainerView!
	@IBOutlet weak var actionButton: CustomisableButton!
	
	@IBOutlet weak var delegateAndStakeContainer: UIView!
	@IBOutlet weak var stakeOnlyContainer: UIView!
	
	private var childNavigationController: UINavigationController? = nil
	private var currentChildViewController: UIViewController? = nil
	private var bag = [AnyCancellable]()
	private var currentStep: String = ""
	private var isStakeOnly = false
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		isStakeOnly = (DependencyManager.shared.balanceService.account.delegate != nil)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		isStakeOnly = (DependencyManager.shared.balanceService.account.delegate != nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		actionButton.customButtonType = .primary
		
		
		// If user only needs to stake we hide the first few screens and 2 steps
		delegateAndStakeContainer.isHidden = isStakeOnly
		stakeOnlyContainer.isHidden = !isStakeOnly
		
		if isStakeOnly {
			indicatorStackview.removeArrangedSubview(pageIndicator1)
			pageIndicator1.isHidden = true
			indicatorStackview.removeArrangedSubview(pageIndicator2)
			pageIndicator2.isHidden = true
			progressSegment1.removeFromSuperview()
			
			// With only 2 steps it looks odd to have it the full length of the screen, reduce it a bit
			indicatorStackviewLeadingConstraint.constant = 24 * 5
			indicatorStackviewTrailingConstraint.constant = 24 * 5
		}
		
		// triple make sure activity listener is up and running before we start
		AccountViewModel.setupAccountActivityListener()
		
		// Listen for requests to add pending operations
		DependencyManager.shared.activityService.$addressesWithPendingOperation
			.dropFirst()
			.sink { [weak self] addresses in
				guard let address = DependencyManager.shared.selectedWalletAddress else {
					return
				}
				
				DispatchQueue.main.async { [weak self] in
					if addresses.contains([address]) {
						self?.showLoadingView()
						self?.updateLoadingViewStatusLabel(message: "Waiting for transaction to complete \n\nThis should only take a few seconds")
						
					} else {
						self?.hideLoadingView()
						self?.handleOperationComplete()
					}
				}
			}.store(in: &bag)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	func setProgressSegmentComplete(_ view: UIProgressView?) {
		UIView.animate(withDuration: 0.7) {
			view?.setProgress(1, animated: true)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if !isStakeOnly, segue.identifier == "embed-delegate", let dest = segue.destination as? UINavigationController {
			childNavigationController = dest
			
		} else if isStakeOnly, segue.identifier == "embed-stake", let dest = segue.destination as? UINavigationController {
			childNavigationController = dest
		}
	}
	
	@IBAction func actionButtonTapped(_ sender: Any) {
		guard let childNav = childNavigationController, let currentChildVc = childNav.viewControllers.last else {
			self.windowError(withTitle: "error".localized(), description: "Unknown error")
			return
		}
		
		currentChildViewController = currentChildVc
		currentStep = currentChildVc.title ?? ""
		
		switch currentChildVc.title {
			case "step1":
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				self.pageIndicator1.setInprogress(pageNumber: 1)
				
			case "step2":
				if handlePageControllerNext(vc: currentChildVc) == true {
					actionButton.setTitle("Choose Baker", for: .normal)
					self.pageIndicator1.setComplete()
					self.setProgressSegmentComplete(self.progressSegment1)
					self.pageIndicator2.setInprogress(pageNumber: 2)
				}
				
			case "step3":
				self.performSegue(withIdentifier: "chooseBaker", sender: nil)
				
			case "step4":
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				
				if isStakeOnly {
					self.pageIndicator3.setInprogress(pageNumber: 1)
				}
				
			case "step5":
				if handlePageControllerNext(vc: currentChildVc) == true {
					actionButton.setTitle("Stake", for: .normal)
					self.pageIndicator3.setComplete()
					self.setProgressSegmentComplete(self.progressSegment3)
					self.pageIndicator4.setInprogress(pageNumber: isStakeOnly ? 2 : 4)
				}
				
			case "step6":
				TransactionService.shared.currentTransactionType = .stake
				TransactionService.shared.stakeData.chosenToken = Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
				// chosenBaker will be set inside the the delegation flow
				self.performSegue(withIdentifier: "stake", sender: nil)
				
			case "step7":
				self.navigationController?.popToDetails()
				
			default:
				self.windowError(withTitle: "error".localized(), description: "Unknown error")
		}
	}
	
	private func handleOperationComplete() {
		switch currentStep {
			case "step3":
				self.pageIndicator2.setComplete()
				self.setProgressSegmentComplete(self.progressSegment2)
				self.pageIndicator3.setInprogress(pageNumber: 3)
				self.currentChildViewController?.performSegue(withIdentifier: "next", sender: nil)
				self.actionButton.setTitle("Next", for: .normal)
				
			case "step6":
				self.pageIndicator4.setComplete()
				self.currentChildViewController?.performSegue(withIdentifier: "next", sender: nil)
				self.actionButton.setTitle("Done", for: .normal)
				
			default:
				self.windowError(withTitle: "error".localized(), description: "Unknown error")
		}
	}
	
	private func handlePageControllerNext(vc: UIViewController) -> Bool? {
		guard let pageController = (vc as? OnboardingPageViewController), let pageControl = pageController.pageControl else {
			self.windowError(withTitle: "error".localized(), description: "Unknown error")
			return nil
		}
		
		if pageControl.currentPage == pageControl.numberOfPages-1 {
			vc.performSegue(withIdentifier: "next", sender: nil)
			return true
		} else {
			pageController.scrollTo(index: (pageController.pageControl?.currentPage ?? 0) + 1)
			return false
		}
	}
}
