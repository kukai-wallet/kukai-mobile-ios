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
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.pageIndicator1.setInprogress(pageNumber: 1)
		
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
	}
	
	func setProgressSegmentComplete(_ view: UIProgressView?) {
		UIView.animate(withDuration: 0.7) {
			view?.setProgress(1, animated: true)
		}
	}
}
