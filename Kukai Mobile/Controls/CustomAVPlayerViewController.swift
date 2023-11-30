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
	
	public weak var customDelegate: CustomAVPlayerViewControllerDelegate? = nil
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		let container = view.subviews.first
		viewToMonitor = container?.subviews.last
		previousValue = viewToMonitor?.isHidden ?? true
		
		viewToMonitor?.addObserver(self, forKeyPath: "hidden", context: nil)
	}
	
	deinit {
		viewToMonitor?.removeObserver(self, forKeyPath: "hidden")
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		// Check if its the correct element and avoid double trigger
		if keyPath == "hidden", let v = viewToMonitor, previousValue != v.isHidden {
			previousValue = v.isHidden
			customDelegate?.playbackControlsChanged(visible: !v.isHidden)
		}
	}
}
