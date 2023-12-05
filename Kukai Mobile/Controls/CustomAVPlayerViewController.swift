//
//  CustomAVPlayerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/10/2023.
//

import AVKit

protocol CustomAVPlayerViewControllerDelegate: AnyObject {
	
	func playbackControlsChanged(visible: Bool)
}

class CustomAVPlayerViewController: AVPlayerViewController {
	
	private var viewToMonitor: UIView? = nil
	private var previousValue = true
	private var hiddenObserver: NSKeyValueObservation? = nil
	
	public weak var customDelegate: CustomAVPlayerViewControllerDelegate? = nil
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		let container = view.subviews.first
		viewToMonitor = container?.subviews.last
		previousValue = viewToMonitor?.isHidden ?? true
		
		viewToMonitor?.addObserver(self, forKeyPath: "hidden", context: nil)
		
		self.hiddenObserver = viewToMonitor?.observe(\.isHidden, changeHandler: { [weak self] view, change in
			if self?.previousValue != view.isHidden {
				self?.previousValue = view.isHidden
				self?.customDelegate?.playbackControlsChanged(visible: !view.isHidden)
			}
		})
		
	}
	
	deinit {
		hiddenObserver?.invalidate()
		hiddenObserver = nil
	}
}
