//
//  StakeOnboardingContainerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/11/2024.
//

import UIKit

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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		actionButton.customButtonType = .primary
		self.pageIndicator1.setInprogress(pageNumber: 1)
		
		//NotificationCenter.default.addObserver(self, selector: #selector(bakerConfirmation), name: ChooseBakerViewController.notificationNameBakerChosen, object: nil)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		/*
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
			self?.pageIndicator1.setComplete()
			self?.setProgressSegmentComplete(self?.progressSegment1)
			self?.pageIndicator2.setInprogress(pageNumber: 2)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
			self?.pageIndicator2.setComplete()
			self?.setProgressSegmentComplete(self?.progressSegment2)
			self?.pageIndicator3.setInprogress(pageNumber: 3)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 9) { [weak self] in
			self?.pageIndicator3.setComplete()
			self?.setProgressSegmentComplete(self?.progressSegment3)
			self?.pageIndicator4.setInprogress(pageNumber: 4)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
			self?.pageIndicator4.setComplete()
			self?.setProgressSegmentComplete(self?.progressSegment4)
			self?.pageIndicator5.setInprogress(pageNumber: 5)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
			self?.pageIndicator5.setComplete()
		}
		*/
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		//NotificationCenter.default.removeObserver(self, name: ChooseBakerViewController.notificationNameBakerChosen, object: nil)
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
		switch currentChildVc.title {
			case "step1":
				currentChildVc.performSegue(withIdentifier: "next", sender: nil)
				self.pageIndicator1.setComplete()
				self.setProgressSegmentComplete(self.progressSegment1)
				self.pageIndicator2.setInprogress(pageNumber: 2)
				
			case "step2":
				if handlePageControllerNext(vc: currentChildVc) == true {
					actionButton.setTitle("Choose Baker", for: .normal)
					self.pageIndicator2.setComplete()
					self.setProgressSegmentComplete(self.progressSegment2)
					self.pageIndicator3.setInprogress(pageNumber: 3)
				}
				
			case "step3":
				self.performSegue(withIdentifier: "chooseBaker", sender: nil)
				
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
	
	/*
	@objc private func bakerConfirmation() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			self?.hideLoadingView()
			self?.performSegue(withIdentifier: "confirmBaker", sender: nil)
		}
	}
	*/
}
