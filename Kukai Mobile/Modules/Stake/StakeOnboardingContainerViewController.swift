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
	
	@IBOutlet weak var pageIndicator1: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment1: UIProgressView!
	@IBOutlet weak var pageIndicator2: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment2: UIProgressView!
	@IBOutlet weak var pageIndicator3: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment3: UIProgressView!
	@IBOutlet weak var pageIndicator4: PageIndicatorContainerView!
	@IBOutlet weak var progressSegment4: UIProgressView!
	@IBOutlet weak var pageIndicator5: PageIndicatorContainerView!
	@IBOutlet weak var actionButton: CustomisableButton!
	
	@IBOutlet weak var navigationContainerView: UIView!
	private var childNavigationController: UINavigationController? = nil
	private var currentChildViewController: UIViewController? = nil
	private var bag = [AnyCancellable]()
	private var currentStep: String = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		actionButton.customButtonType = .primary
		
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
	
	@IBAction func closeTapped(_ sender: Any) {
		self.navigationController?.popToDetails()
	}
	
	func setProgressSegmentComplete(_ view: UIProgressView?) {
		UIView.animate(withDuration: 0.7) {
			view?.setProgress(1, animated: true)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "embed", let dest = segue.destination as? UINavigationController {
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
				
			case "step5":
				if handlePageControllerNext(vc: currentChildVc) == true {
					actionButton.setTitle("Stake", for: .normal)
					self.pageIndicator3.setComplete()
					self.setProgressSegmentComplete(self.progressSegment3)
					self.pageIndicator4.setInprogress(pageNumber: 4)
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
				self.setProgressSegmentComplete(self.progressSegment4)
				self.pageIndicator5.setInprogress(pageNumber: 5)
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
