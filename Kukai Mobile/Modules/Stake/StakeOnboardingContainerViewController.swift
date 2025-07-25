//
//  StakeOnboardingContainerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/11/2024.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

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
	
	private var backupTimer: Timer? = nil
	private var numberOfTimesPendingCalled = 0
	private var pendingHandledByAutomaticChecker = false
	private var pendingHandledByManualChecker = false
	private var numberOfManualChecks = 0
	
	private let backButton = UIButton(type: .custom)
	
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
		
		self.navigationItem.setHidesBackButton(true, animated: false)
		addBackButton()
		
		// If user only needs to stake we hide the first few screens and 2 steps
		delegateAndStakeContainer.isHidden = isStakeOnly
		stakeOnlyContainer.isHidden = !isStakeOnly
		
		if isStakeOnly {
			self.title = "Start Staking"
			
			indicatorStackview.removeArrangedSubview(pageIndicator1)
			pageIndicator1.isHidden = true
			indicatorStackview.removeArrangedSubview(pageIndicator2)
			pageIndicator2.isHidden = true
			progressSegment1.removeFromSuperview()
			
			// With only 2 steps it looks odd to have it the full length of the screen, reduce it a bit
			indicatorStackviewLeadingConstraint.constant = 24 * 5
			indicatorStackviewTrailingConstraint.constant = 24 * 5
		} else {
			self.title = "Getting Started"
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
						self?.numberOfTimesPendingCalled += 1
						self?.pendingHandledByAutomaticChecker = false
						self?.pendingHandledByManualChecker = false
						self?.numberOfManualChecks = 0
						self?.backupOperationCompleteChecker(withTime: 12)
						
						if let childNav = self?.childNavigationController, let currentChildVc = childNav.viewControllers.last {
							currentChildVc.performSegue(withIdentifier: "next", sender: nil)
							self?.navigationController?.navigationBar.isHidden = true
							self?.actionButton.isHidden = true
							self?.hideStepIndicator()
							
							if self?.currentStep == "step6" {
								self?.actionButton.setTitle("Continue", for: .normal)
							} else {
								self?.actionButton.setTitle("Done", for: .normal)
							}
						}
						
					} else {
						self?.backupTimer?.invalidate()
						self?.backupTimer = nil
						self?.pendingHandledByAutomaticChecker = true
						
						self?.handleOperationComplete()
					}
				}
			}.store(in: &bag)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.navigationItem.setHidesBackButton(false, animated: false)
		
		backupTimer?.invalidate()
		backupTimer = nil
	}
	
	func addBackButton() {
		backButton.setImage(UIImage(named: "ChevronLeft"), for: .normal)
		backButton.setTitle("  ", for: .normal)
		backButton.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
	}
	
	// Custom back button handler, so user doesn't have to back all the way out to re-read something
	@objc func handleBackButtonTapped() {
		guard let childNav = childNavigationController else {return}
		
		if childNav.viewControllers.count == 1 || (self.title == "Stake for Higher Rewards" && childNav.viewControllers.count > 2) {
			self.navigationController?.popViewController(animated: true)
		} else {
			childNavigationController?.popViewController(animated: true)
			updateProgressBarForCustomBack()
		}
	}
	
	func setProgressSegmentComplete(_ view: UIProgressView?) {
		UIView.animate(withDuration: 0.7) {
			view?.setProgress(1, animated: true)
		}
	}
	
	func setProgressSegmentIncomplete(_ view: UIProgressView?) {
		UIView.animate(withDuration: 0.7) {
			view?.setProgress(0, animated: true)
		}
	}
	
	@objc private func handleDisplayTransactionPending() {
		self.performSegue(withIdentifier: "transaction-processing-1", sender: nil)
	}
	
	func hideStepIndicator() {
		
		if isStakeOnly {
			progressSegment3.isHidden = true
		} else {
			progressSegment1.isHidden = true
			progressSegment2.isHidden = true
			progressSegment3.isHidden = true
		}
		
		indicatorStackview.isHidden = true
	}
	
	func showStepIndicator() {
		if isStakeOnly {
			progressSegment3.isHidden = false
		} else {
			progressSegment1.isHidden = false
			progressSegment2.isHidden = false
			progressSegment3.isHidden = false
		}
		
		indicatorStackview.isHidden = false
	}
	
	private func backupOperationCompleteChecker(withTime: TimeInterval) {
		
		self.backupTimer = Timer.scheduledTimer(withTimeInterval: withTime, repeats: false, block: { [weak self] t in
			guard self?.pendingHandledByAutomaticChecker == false else {
				Logger.app.info("backupOperationCompleteChecker exiting due to automatic check succeeding")
				return
			}
			
			Logger.app.info("backupOperationCompleteChecker proceeding due to automatic check failing")
			let currentAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			DependencyManager.shared.tzktClient.getAccount(forAddress: currentAddress) { result in
				self?.numberOfManualChecks += 1
				
				guard let res = try? result.get() else {
					self?.backupOperationCheckerFail()
					Logger.app.error("backupOperationCompleteChecker encountered failure fetching account")
					return
				}
				
				if self?.numberOfTimesPendingCalled == 1 && self?.isStakeOnly == false {
					if res.delegate != nil {
						Logger.app.info("backupOperationCompleteChecker delegation check succeeded")
						self?.backupOperationCheckerSuccess()
					} else {
						Logger.app.error("backupOperationCompleteChecker delegation check failed")
						self?.backupOperationCheckerFail()
					}
					
				} else if (self?.numberOfTimesPendingCalled == 2 && self?.isStakeOnly == false) || self?.isStakeOnly == true {
					if (res.stakedBalance ?? 0) > 0 {
						Logger.app.info("backupOperationCompleteChecker stake check succeeded")
						self?.backupOperationCheckerSuccess()
					} else {
						Logger.app.error("backupOperationCompleteChecker stake check failed")
						self?.backupOperationCheckerFail()
					}
				}
			}
		})
	}
	
	private func backupOperationCheckerSuccess() {
		DispatchQueue.main.async { [weak self] in
			self?.hideLoadingView()
			self?.handleOperationComplete()
		}
	}
	
	private func backupOperationCheckerFail() {
		if numberOfManualChecks <= 1 {
			backupOperationCompleteChecker(withTime: 12)
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.hideLoadingView()
				self?.windowError(withTitle: "error".localized(), description: "error-stake-wizard-unknown".localized())
				self?.navigationController?.popToDetails()
			}
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
				self.title = "Start by Delegating"
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				self.pageIndicator1.setInprogress(pageNumber: 1)
				
			case "step2":
				self.title = "Bakers and Governance"
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				actionButton.setTitle("Select Baker", for: .normal)
				self.pageIndicator1.setComplete()
				self.setProgressSegmentComplete(self.progressSegment1)
				self.pageIndicator2.setInprogress(pageNumber: 2)
				
			case "step3":
				self.performSegue(withIdentifier: "chooseBaker", sender: nil)
				
			case "step4":
				self.title = "Stake for Higher Rewards"
				self.navigationController?.navigationBar.isHidden = false
				self.view.setNeedsLayout()
				
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				
				self.showStepIndicator()
				
				if isStakeOnly {
					self.pageIndicator3.setInprogress(pageNumber: 1)
				}
				
			case "step5":
				self.title = "Stake Amount"
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				actionButton.setTitle("Enter Amount", for: .normal)
				self.pageIndicator3.setComplete()
				self.setProgressSegmentComplete(self.progressSegment3)
				self.pageIndicator4.setInprogress(pageNumber: isStakeOnly ? 2 : 4)
				
			case "step6":
				TransactionService.shared.currentTransactionType = .stake
				TransactionService.shared.stakeData.chosenToken = Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
				// chosenBaker will be set inside the the delegation flow
				self.performSegue(withIdentifier: "stake", sender: nil)
				
			case "step7":
				self.navigationController?.navigationBar.isHidden = false
				self.navigationController?.popToDetails()
				
			default:
				self.windowError(withTitle: "error".localized(), description: "Unknown error")
		}
	}
	
	private func updateProgressBarForCustomBack() {
		// quick hacky way for now, should be cleaned up and made more generic/reusable later when we use this control more
		
		guard let childNav = childNavigationController, let currentChildVc = childNav.viewControllers.last else {
			self.windowError(withTitle: "error".localized(), description: "Unknown error")
			return
		}
		
		currentChildViewController = currentChildVc
		currentStep = currentChildVc.title ?? ""
		let newStepNumber = (Int(String(currentStep.last ?? "2")) ?? 2) - 1
		let newStep = "step\(newStepNumber)"
		
		switch newStep {
			case "step0":
				self.title = "Getting Started"
				self.pageIndicator1.setPending()
				
			case "step1":
				self.title = "Start by Delegating"
				self.pageIndicator1.setInprogress(pageNumber: 1)
				self.setProgressSegmentIncomplete(self.progressSegment1)
				self.pageIndicator2.setPending()
			
			case "step3":
				// only possible in stake-only flow
				self.title = "Start Staking"
				self.pageIndicator3.setPending()
				
			
			case "step4":
				self.title = "Stake for Higher Rewards"
				
				self.pageIndicator3.setInprogress(pageNumber: 3)
				self.setProgressSegmentIncomplete(self.progressSegment3)
				self.pageIndicator4.setPending()
				
				if isStakeOnly {
					self.pageIndicator3.setInprogress(pageNumber: 1)
					self.setProgressSegmentIncomplete(self.progressSegment3)
					self.pageIndicator4.setPending()
				}
				
			default:
				let _ = ""
		}
	}
	
	private func handleOperationComplete() {
		switch currentStep {
			case "step3":
				self.pageIndicator2.setComplete()
				self.setProgressSegmentComplete(self.progressSegment2)
				self.pageIndicator3.setInprogress(pageNumber: 3)
				
				self.actionButton.setTitle("Next", for: .normal)
				self.actionButton.isHidden = false
				
			case "step6":
				self.pageIndicator4.setComplete()
				self.actionButton.setTitle("Done", for: .normal)
				self.actionButton.isHidden = false
				
			default:
				let _ = ""
				//self.windowError(withTitle: "error".localized(), description: "Unknown error")
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
