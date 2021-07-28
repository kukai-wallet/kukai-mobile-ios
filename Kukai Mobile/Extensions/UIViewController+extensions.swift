//
//  UIViewController+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

extension UIViewController {
	
	// MARK: - Flow
	
	func isPartOfSideMenuImportFlow() -> Bool {
		return self.navigationController?.presentingViewController is SideMenuViewController
	}
	
	func completeAndCloseSideMenuImport() {
		if let sideMenu = self.navigationController?.presentingViewController as? SideMenuViewController {
			sideMenu.viewModel.refresh(animate: true)
			self.navigationController?.dismiss(animated: true, completion: nil)
		}
	}
	
	
	
	// MARK: - Activity display
	
	private static var activityView = UIView()
	
	func showActivity(clearBackground: Bool = true) {
		UIViewController.activityView = UIView(frame: UIScreen.main.bounds)
		UIViewController.activityView.translatesAutoresizingMaskIntoConstraints = false
		UIViewController.activityView.backgroundColor = clearBackground ? .clear : UIColor.lightGray.withAlphaComponent(0.7)
		
		let activityIndicator = UIActivityIndicatorView(style: .medium)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		UIViewController.activityView.addSubview(activityIndicator)
		self.view.addSubview(UIViewController.activityView)
		self.view.bringSubviewToFront(UIViewController.activityView)
		
		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: UIViewController.activityView.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: UIViewController.activityView.centerYAnchor),
			
			UIViewController.activityView.topAnchor.constraint(equalTo: self.view.topAnchor),
			UIViewController.activityView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
			UIViewController.activityView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			UIViewController.activityView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
		])
		
		activityIndicator.startAnimating()
	}
	
	func hideActivity() {
		self.view.removeConstraints(UIViewController.activityView.constraints)
		UIViewController.activityView.removeFromSuperview()
	}
	
	var isModal: Bool {
		let presentingIsModal = presentingViewController != nil
		let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
		let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

		return presentingIsModal || presentingIsNavigation || presentingIsTabBar
	}
	
	func hideAllSubviews() {
		for v in view.subviews {
			v.isHidden = true
		}
	}
	
	func showAllSubviews() {
		for v in view.subviews {
			v.isHidden = false
		}
	}
	
	
	
	// MARK: - UIAlertViewController Utils
	
	func alert(errorWithMessage message: String) {
		alert(withTitle: "error".localized, andMessage: message)
	}
	
	func alert(withTitle title: String, andMessage message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let action = UIAlertAction(title: "ok".localized, style: .default, handler: nil)
		alert.addAction(action)
		
		DispatchQueue.main.async {
			self.present(alert, animated: Thread.current.isRunningXCTest ? false : true, completion: nil)
		}
	}
	
	func alert(withTitle title: String, andMessage message: String, okText: String = "ok".localized, okAction: @escaping ((UIAlertAction) -> Void), cancelText: String = "cancel".localized, cancelAction: ((UIAlertAction) -> Void)? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: okText, style: .default, handler: okAction)
		let cancelAction = UIAlertAction(title: cancelText, style: .default, handler: cancelAction)
		alert.addAction(okAction)
		alert.addAction(cancelAction)
		
		DispatchQueue.main.async {
			self.present(alert, animated: Thread.current.isRunningXCTest ? false : true, completion: nil)
		}
	}
	
	
	
	// MARK: - Storybaord Utils
	
	@IBAction func modalCloseButtonTapped(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
	
	
	
	// MARK: - Keyboard

	func addKeyboardObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	func removeKeyboardObservers() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			if self.view.frame.height == UIScreen.main.bounds.height {
				var newRect = self.view.frame
				newRect.size = CGSize(width: newRect.width, height: (newRect.height - keyboardSize.height))
				
				self.view.frame = newRect
			}
		}
	}

	@objc func keyboardWillHide(notification: NSNotification) {
		if self.view.frame.height != UIScreen.main.bounds.height {
			self.view.frame = UIScreen.main.bounds
		}
	}
}
