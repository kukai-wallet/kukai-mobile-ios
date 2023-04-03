//
//  AutoScrollView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

protocol AutoScrollViewDelegate: AnyObject {
	func keyboardWillShow()
	func keyboardWillHide()
}

class AutoScrollView: UIScrollView {
	
	public weak var parentView: UIView? = nil
	public weak var viewToFocusOn: UIView? = nil
	public weak var autoScrollDelegate: AutoScrollViewDelegate? = nil
	
	func setupAutoScroll(focusView: UIView, parentView: UIView) {
		self.viewToFocusOn = focusView
		self.parentView = parentView
		
		NotificationCenter.default.addObserver(self, selector: #selector(customKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(customKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func stopAutoScroll() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func customKeyboardWillShow(notification: NSNotification) {
		guard let parentView = parentView, let viewToFocusOn = viewToFocusOn else { return }
		
		autoScrollDelegate?.keyboardWillShow()
		
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			let whereKeyboardWillGoToo = ((self.frame.height + parentView.safeAreaInsets.bottom) - keyboardSize.height)
			let whereNeedsToBeDisplayed = (viewToFocusOn.convert(CGPoint(x: 0, y: 0), to: self).y + viewToFocusOn.frame.height + 8).rounded(.up)
			
			if whereKeyboardWillGoToo < whereNeedsToBeDisplayed {
				self.contentOffset = CGPoint(x: 0, y: (whereNeedsToBeDisplayed - whereKeyboardWillGoToo))
			}
		}
	}
	
	@objc func customKeyboardWillHide(notification: NSNotification) {
		autoScrollDelegate?.keyboardWillHide()
		
		if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			self.contentOffset = CGPoint(x: 0, y: 0)
		}
	}
}
