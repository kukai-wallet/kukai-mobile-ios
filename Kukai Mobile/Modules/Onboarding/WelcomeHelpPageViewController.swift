//
//  WelcomeHelpPageViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/07/2021.
//

import UIKit

class WelcomeHelpPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	public var items: [UIViewController] = []
	private var pageControl: UIPageControl? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		items.append(UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(identifier: "welcome-help-page-1"))
		items.append(UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(identifier: "welcome-help-page-2"))
		items.append(UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(identifier: "welcome-help-page-3"))
		items.append( UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(identifier: "welcome-help-page-4"))
		
		setViewControllers([items[0]], direction: .forward, animated: true, completion: nil)
		self.dataSource = self
		self.delegate = self
		
		
		pageControl = UIPageControl()
		pageControl?.translatesAutoresizingMaskIntoConstraints = false
		pageControl?.numberOfPages = items.count
		pageControl?.currentPage = 0
		pageControl?.currentPageIndicatorTintColor = .systemBlue
		pageControl?.pageIndicatorTintColor = .lightGray
		pageControl?.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
		
		if let pc = pageControl {
			self.view.addSubview(pc)
			self.view.addConstraints([
				NSLayoutConstraint(item: pc, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 24),
				NSLayoutConstraint(item: pc, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -24),
				NSLayoutConstraint(item: pc, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
			])
		}
    }
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		guard let viewControllerIndex = items.firstIndex(of: viewController) else {
			return nil
		}
		
		if viewControllerIndex == 0 {
			return nil
		} else {
			return items[viewControllerIndex-1]
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		guard let viewControllerIndex = items.firstIndex(of: viewController) else {
			return nil
		}
		
		if viewControllerIndex == items.count-1 {
			return nil
		} else {
			return items[viewControllerIndex+1]
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		guard let currentVc = pageViewController.viewControllers?.first, let viewControllerIndex = items.firstIndex(of: currentVc) else {
			return
		}
		
		pageControl?.currentPage = viewControllerIndex
	}
	
	@objc func pageControlTapped() {
		guard let currentVc = self.viewControllers?.first, let viewControllerIndex = items.firstIndex(of: currentVc) else {
			return
		}
		
		let vc = items[pageControl?.currentPage ?? 0]
		let isForward = viewControllerIndex < (pageControl?.currentPage ?? 0)
		
		self.setViewControllers([vc], direction: isForward ? .forward : .reverse, animated: true, completion: nil)
	}
}
