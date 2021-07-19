//
//  OnboardingPageViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2021.
//

import UIKit

/// A wrapper around the UIPageViewController that takes in a collection of viewControllers via an `IBInspectable`, and implements all the standard scroll logic and UIPageControl
/// to create an onboarding / intro / explanitory section in the app, to visually explain a topic or collection of topics to the user.
class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	public var items: [UIViewController] = []
	private var pageControl: UIPageControl? = nil
	
	/**
	comma separated string containing any number of UIViewController storyboard ids, used to init UIViewControllers to act as pages in the page view controller
	*/
	@IBInspectable var commaSeperatedStoryboardIds: String = ""
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let ids = commaSeperatedStoryboardIds.components(separatedBy: ",")
		for id in ids {
			items.append(self.storyboard?.instantiateViewController(identifier: id) ?? UIViewController())
		}
		
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
