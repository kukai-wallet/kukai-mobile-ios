//
//  UIViewController+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

extension UIViewController {
	
	// MARK: - Flow
	
	func isAddingAdditionalWallet() -> Bool {
		return (self.navigationController?.presentingViewController is AccountsViewController) || (self.navigationController?.presentingViewController is AddWalletViewController)
	}
	
	func returnToAccountsFromAddWallet() {
		self.navigationController?.presentingViewController?.dismiss(animated: true)
		self.navigationController?.presentingViewController?.presentingViewController?.dismiss(animated: true)
	}
	
	
	
	// MARK: - Activity display
	
	private static var activityView = createActivityView()
	private static var activityViewActivityIndicator = UIActivityIndicatorView()
	
	private static var activityIndicator = UIActivityIndicatorView()
	private static var loadingModal = UIViewController.createLoadingModal()
	private static var loadingModalStatusLabel = UILabel()
	
	static func createActivityView() -> UIView {
		let view = UIView(frame: UIScreen.main.bounds)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
		
		UIViewController.activityViewActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
		UIViewController.activityViewActivityIndicator.color = UIColor.white
		
		view.addSubview(UIViewController.activityViewActivityIndicator)
		view.bringSubviewToFront(UIViewController.activityViewActivityIndicator)
		
		UIViewController.activityViewActivityIndicator.center = view.center
		
		return view
	}
	
	func showLoadingView(completion: (() -> Void)? = nil) {
		UIViewController.activityViewActivityIndicator.startAnimating()
		UIApplication.shared.currentWindow?.addSubview(UIViewController.activityView)
	}
	
	func hideLoadingView(completion: (() -> Void)? = nil) {
		UIViewController.activityViewActivityIndicator.stopAnimating()
		UIViewController.activityView.removeFromSuperview()
	}
	
	static func createLoadingModal() -> UIViewController {
		let vc = UIViewController()
		vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
		
		UIViewController.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		UIViewController.activityIndicator.color = UIColor.white
		
		loadingModalStatusLabel.translatesAutoresizingMaskIntoConstraints = false
		loadingModalStatusLabel.numberOfLines = 0
		loadingModalStatusLabel.textColor = UIColor.white
		loadingModalStatusLabel.textAlignment = .center
		
		vc.view.addSubview(UIViewController.activityIndicator)
		vc.view.addSubview(UIViewController.loadingModalStatusLabel)
		vc.view.bringSubviewToFront(UIViewController.activityIndicator)
		
		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
			
			loadingModalStatusLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 20),
			loadingModalStatusLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -20),
			loadingModalStatusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
		])
		
		vc.modalPresentationStyle = .overFullScreen
		vc.modalTransitionStyle = .crossDissolve
		
		return vc
	}
	
	func updateLoadingModalStatusLabel(message: String) {
		UIViewController.loadingModalStatusLabel.text = message
	}
	
	func showLoadingModal(completion: (() -> Void)? = nil) {
		UIViewController.activityIndicator.startAnimating()
		self.present(UIViewController.loadingModal, animated: true, completion: completion)
	}
	
	func hideLoadingModal(completion: (() -> Void)? = nil) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			UIViewController.activityIndicator.stopAnimating()
			UIViewController.loadingModal.dismiss(animated: true, completion: completion)
		}
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
		alert(withTitle: "error", andMessage: message)
	}
	
	func alert(withTitle title: String, andMessage message: String) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let action = UIAlertAction(title: "ok", style: .default, handler: nil)
			alert.addAction(action)
			
			self.present(alert, animated: Thread.current.isRunningXCTest ? false : true, completion: nil)
		}
	}
	
	func alert(withTitle title: String, andMessage message: String, okText: String = "ok", okAction: @escaping ((UIAlertAction) -> Void)) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okText, style: .default, handler: okAction)
			alert.addAction(okAction)
			
			self.present(alert, animated: Thread.current.isRunningXCTest ? false : true, completion: nil)
		}
	}
	
	func alert(withTitle title: String, andMessage message: String, okText: String = "ok", okAction: @escaping ((UIAlertAction) -> Void), cancelText: String = "cancel", cancelAction: @escaping ((UIAlertAction) -> Void)) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okText, style: .default, handler: okAction)
			let cancelAction = UIAlertAction(title: cancelText, style: .default, handler: cancelAction)
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			
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
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? String), duration != "0" {
			var newRect = self.view.bounds
			newRect.size = CGSize(width: newRect.width, height: (newRect.height - keyboardSize.height))
			
			self.view.frame = newRect
		}
	}

	@objc func keyboardWillHide(notification: NSNotification) {
		
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? String), duration != "0" {
			var newRect = self.view.bounds
			newRect.size = CGSize(width: newRect.width, height: (newRect.height + keyboardSize.height))
			
			self.view.frame = newRect
		}
	}
	
	
	
	// MARK: - Bottom Sheets
	
	/// Calling parent.dismiss doesn't trigger delegate methods. Create workaround to allow parent to automatically call
	public func dismissBottomSheet() {
		guard let presentingController = self.presentingViewController, let sheet = self.presentationController as? UISheetPresentationController else {
			return
		}
		
		sheet.delegate?.presentationControllerWillDismiss?(sheet)
		presentingController.dismiss(animated: true, completion: {
			sheet.delegate?.presentationControllerDidDismiss?(sheet)
		})
	}
}



/// Make bottom sheets automatically call viewWill / viewDidAppear on the main screen while dismissing (if delegate is set)
extension UIViewController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		self.viewWillAppear(true)
	}
	
	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		self.viewDidAppear(true)
	}
}
