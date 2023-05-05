//
//  OnboardingPageViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2021.
//

import UIKit

protocol OnboardingPageViewControllerDelegate: AnyObject {
	func didMove(toIndex index: Int)
	func willMoveToParent()
}

/// A wrapper around the UIPageViewController that takes in a collection of viewControllers via an `IBInspectable`, and implements all the standard scroll logic and UIPageControl
/// to create an onboarding / intro / explanitory section in the app, to visually explain a topic or collection of topics to the user.
class OnboardingPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
	
	public var items: [UIViewController] = []
	public var startIndex: Int = 0
	private var pageControl: UIPageControl? = nil
	
	/**
	comma separated string containing any number of UIViewController storyboard ids, used to init UIViewControllers to act as pages in the page view controller
	*/
	@IBInspectable var commaSeperatedStoryboardIds: String = ""
	
	@IBInspectable var showPageControl: Bool = true
	
	public weak var pageDelegate: OnboardingPageViewControllerDelegate? = nil
	
	required init?(coder: NSCoder) {
		super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let ids = commaSeperatedStoryboardIds.components(separatedBy: ",")
		for id in ids {
			items.append(self.storyboard?.instantiateViewController(identifier: id) ?? UIViewController())
		}
		
		setViewControllers([items[0]], direction: .forward, animated: false, completion: nil)
		self.dataSource = self
		self.delegate = self
		
		pageControl = UIPageControl()
		pageControl?.translatesAutoresizingMaskIntoConstraints = false
		pageControl?.numberOfPages = items.count
		pageControl?.currentPage = 0
		pageControl?.currentPageIndicatorTintColor = .colorNamed("Txt2")
		pageControl?.pageIndicatorTintColor = .colorNamed("Txt10")
		pageControl?.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
		
		if let pc = pageControl {
			self.view.addSubview(pc)
			self.view.addConstraints([
				NSLayoutConstraint(item: pc, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 24),
				NSLayoutConstraint(item: pc, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -24),
				NSLayoutConstraint(item: pc, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottomMargin, multiplier: 1, constant: 0)
			])
		}
	}
	
	override func willMove(toParent parent: UIViewController?) {
		pageDelegate?.willMoveToParent()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setViewControllers([items[startIndex]], direction: .forward, animated: false, completion: nil)
		self.pageControl?.currentPage = startIndex
		
		if !showPageControl {
			pageControl?.isHidden = true
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
		pageDelegate?.didMove(toIndex: viewControllerIndex)
	}
	
	@objc func pageControlTapped() {
		scrollTo(index: pageControl?.currentPage ?? 0)
	}
	
	public func scrollTo(index: Int) {
		guard let currentVc = self.viewControllers?.first, let viewControllerIndex = items.firstIndex(of: currentVc) else {
			return
		}
		
		let vc = items[index]
		let isForward = viewControllerIndex < index
		self.setViewControllers([vc], direction: isForward ? .forward : .reverse, animated: true, completion: nil)
	}
}
