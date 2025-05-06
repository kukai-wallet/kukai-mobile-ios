//
//  UIViewController+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import Sentry

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
	private static var activityViewStatusLabel = UILabel()
	private static var activityViewActivityIndicator = UIActivityIndicatorView(style: .large)
	
	private static var activityIndicator = UIActivityIndicatorView(style: .large)
	private static var loadingModal = UIViewController.createLoadingModal()
	private static var loadingModalStatusLabel = UILabel()
	private static let loadingModalBackgroundColor = UIColor.black.withAlphaComponent(0.75)
	
	static func createActivityView() -> UIView {
		let view = UIView(frame: UIScreen.main.bounds)
		view.backgroundColor = UIViewController.loadingModalBackgroundColor
		
		activityViewStatusLabel.numberOfLines = 0
		activityViewStatusLabel.font = UIFont.custom(ofType: .medium, andSize: 16)
		activityViewStatusLabel.textColor = UIColor.white
		activityViewStatusLabel.textAlignment = .center
		activityViewStatusLabel.frame = CGRect(x: view.center.x, y: view.center.y, width: view.frame.width - 64, height: 200)
		
		UIViewController.activityViewActivityIndicator.color = UIColor.white
		
		view.addSubview(UIViewController.activityViewActivityIndicator)
		view.addSubview(UIViewController.activityViewStatusLabel)
		view.bringSubviewToFront(UIViewController.activityViewActivityIndicator)
		
		UIViewController.activityViewActivityIndicator.center = view.center
		UIViewController.activityViewStatusLabel.center = CGPoint(x: view.center.x, y: (view.center.y + 48))
		
		return view
	}
	
	func showLoadingView() {
		UIViewController.activityViewActivityIndicator.startAnimating()
		UIViewController.activityView.frame = UIScreen.main.bounds
		UIViewController.activityView.alpha = 1
		UIApplication.shared.currentWindow?.addSubview(UIViewController.activityView)
		
		loadingViewShowActivity()
	}
	
	func loadingViewHideActivity() {
		UIViewController.activityViewActivityIndicator.stopAnimating()
		UIViewController.activityViewActivityIndicator.isHidden = true
		UIViewController.activityViewStatusLabel.isHidden = true
		UIViewController.activityView.alpha = 1
	}
	
	func loadingViewShowActivity() {
		UIViewController.activityViewActivityIndicator.startAnimating()
		UIViewController.activityViewActivityIndicator.isHidden = false
		UIViewController.activityViewStatusLabel.isHidden = false
		UIViewController.activityView.alpha = 1
	}
	
	func loadingViewHideActivityAndFade(withDuration duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
		loadingViewHideActivity()
		
		UIView.animate(withDuration: duration) {
			UIViewController.activityView.alpha = 0
		} completion: { _ in
			UIViewController.activityView.removeFromSuperview()
			completion?()
		}
	}
	
	func updateLoadingViewStatusLabel(message: String) {
		UIViewController.activityViewStatusLabel.text = message
	}
	
	func hideLoadingView(completion: (() -> Void)? = nil) {
		UIViewController.activityViewActivityIndicator.stopAnimating()
		UIViewController.activityView.removeFromSuperview()
		UIViewController.activityViewStatusLabel.text = ""
		if let comp = completion {
			comp()
		}
	}
	
	static func removeLoadingView(completion: (() -> Void)? = nil) {
		UIViewController.activityViewActivityIndicator.stopAnimating()
		UIViewController.activityView.removeFromSuperview()
		UIViewController.activityViewStatusLabel.text = ""
		if let comp = completion {
			comp()
		}
	}
	
	static func createLoadingModal() -> UIViewController {
		let vc = UIViewController()
		vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
		
		UIViewController.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		UIViewController.activityIndicator.color = UIColor.white
		
		loadingModalStatusLabel.translatesAutoresizingMaskIntoConstraints = false
		loadingModalStatusLabel.numberOfLines = 0
		loadingModalStatusLabel.font = UIFont.custom(ofType: .medium, andSize: 16)
		loadingModalStatusLabel.textColor = UIColor.white
		loadingModalStatusLabel.textAlignment = .center
		
		vc.view.addSubview(UIViewController.activityIndicator)
		vc.view.addSubview(UIViewController.loadingModalStatusLabel)
		vc.view.bringSubviewToFront(UIViewController.activityIndicator)
		
		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
			
			loadingModalStatusLabel.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 32),
			loadingModalStatusLabel.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -32),
			loadingModalStatusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
		])
		
		vc.modalPresentationStyle = .overFullScreen
		vc.modalTransitionStyle = .crossDissolve
		
		return vc
	}
	
	func updateLoadingModalStatusLabel(message: String) {
		UIViewController.loadingModalStatusLabel.text = message
	}
	
	func showLoadingModal(invisible: Bool = false, completion: (() -> Void)? = nil) {
		guard UIViewController.loadingModal.presentingViewController == nil else {
			return
		}
		
		UIViewController.loadingModalStatusLabel.text = ""
		
		if invisible {
			UIViewController.activityIndicator.isHidden = true
			UIViewController.loadingModal.view.backgroundColor = .clear
			
		} else {
			UIViewController.activityIndicator.isHidden = false
			UIViewController.activityIndicator.startAnimating()
			UIViewController.loadingModal.view.backgroundColor = UIViewController.loadingModalBackgroundColor
		}
		
		self.present(UIViewController.loadingModal, animated: !invisible, completion: completion)
	}
	
	func hideLoadingModal(invisible: Bool = false, completion: (() -> Void)? = nil) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			UIViewController.activityIndicator.stopAnimating()
			UIViewController.loadingModal.dismiss(animated: !invisible, completion: completion)
			UIViewController.loadingModalStatusLabel.text = ""
		}
	}
	
	static func removeLoadingModal(invisible: Bool = false, completion: (() -> Void)? = nil) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			UIViewController.activityIndicator.stopAnimating()
			UIViewController.loadingModal.dismiss(animated: !invisible, completion: completion)
			UIViewController.loadingModalStatusLabel.text = ""
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
			guard !(v is GradientView) else {
				continue
			}
			
			v.isHidden = true
		}
	}
	
	func showAllSubviews() {
		for v in view.subviews {
			v.isHidden = false
		}
	}
	
	
	
	// MARK: - UIAlertViewController Utils
	
	func windowError(withTitle: String, description: String, autoDismiss: TimeInterval? = 10) {
		if let sceneDelgate = (self.view.window?.windowScene?.delegate as? SceneDelegate) {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "displaying windowError 1"))
			sceneDelgate.window?.displayError(title: withTitle, description: description, autoDismiss: autoDismiss)
			
		} else if let sceneDelgate = (self.parent?.view.window?.windowScene?.delegate as? SceneDelegate) {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "displaying windowError 2"))
			sceneDelgate.window?.displayError(title: withTitle, description: description, autoDismiss: autoDismiss)
		}
	}
	
	func alert(errorWithMessage message: String) {
		alert(withTitle: "error".localized(), andMessage: message)
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
	
	func alert(withTitle title: String,
			   andMessage message: String,
			   okText: String = "ok",
			   okStyle: UIAlertAction.Style = .default,
			   okAction: @escaping ((UIAlertAction) -> Void),
			   cancelText: String = "cancel",
			   cancelStyle: UIAlertAction.Style = .default,
			   cancelAction: @escaping ((UIAlertAction) -> Void)) {
		
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
			let okAction = UIAlertAction(title: okText, style: okStyle, handler: okAction)
			let cancelAction = UIAlertAction(title: cancelText, style: cancelStyle, handler: cancelAction)
			alert.addAction(okAction)
			alert.addAction(cancelAction)
			
			self.present(alert, animated: Thread.current.isRunningXCTest ? false : true, completion: nil)
		}
	}
	
	
	
	// MARK: - Storyboard Utils
	
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
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
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
	
	
	
	// MARK: Global styling
	
	open override func awakeAfter(using coder: NSCoder) -> Any? {
		navigationItem.backButtonDisplayMode = .minimal
		self.navigationController?.navigationBar.tintColor = UIColor.colorNamed("TxtB6")
		
		return super.awakeAfter(using: coder)
	}
}
