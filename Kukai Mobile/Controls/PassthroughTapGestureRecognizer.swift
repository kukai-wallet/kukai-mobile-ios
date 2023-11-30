//
//  PassthroughTapGestureRecognizer.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/10/2023.
//

import UIKit

class PassthroughTapGestureRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
	
	private var target: AnyObject? = nil
	private var action: Selector? = nil
	
	init(target: AnyObject?, action: Selector?) {
		super.init(target: target, action: action)
		
		self.target = target
		self.action = action
		self.delegate = self
	}
	
	/// Capture the shouldReceive delegate, always reutrn false, so it will continue downstream, but allow our gesture to trigger anyway
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		let _ = target?.perform(action)
		return false
	}
}
