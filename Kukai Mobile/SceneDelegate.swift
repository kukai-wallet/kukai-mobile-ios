//
//  SceneDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import CustomAuth
import WalletConnectPairing
import KukaiCoreSwift
import Sentry
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	
	var window: UIWindow?
	
	public var firstLoad = true
	//public var privacyProtectionWindowVisible = false
	//private var privacyProtectionWindow: UIWindow = UIWindow()
	
	private var loginVc: UINavigationController? = nil
	
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let scene = (scene as? UIWindowScene) else { return }
		
		//privacyProtectionWindow = UIWindow(windowScene: scene)
		loginVc = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
		WalletConnectService.shared.setup()
		
		scene.windows.forEach { window in
			window.overrideUserInterfaceStyle = ThemeManager.shared.currentInterfaceStyle()
		}
		
		if let url = connectionOptions.urlContexts.first?.url {
			Logger.app.info("Launching with deeplink")
			handleDeeplink(url: url)
			
		} else if let userActivity = connectionOptions.userActivities.first, userActivity.activityType == NSUserActivityTypeBrowsingWeb,  let url = userActivity.webpageURL {
			Logger.app.info("Launching with universal link")
			handleDeeplink(url: url)
			
		} else {
			Logger.app.info("Launching without URL")
		}
	}
	
	func sceneDidDisconnect(_ scene: UIScene) {
	}
	
	func sceneDidBecomeActive(_ scene: UIScene) {
		
		// Check system colors set correctly from beginning
		ThemeManager.shared.updateSystemInterfaceStyle()
		MigrationService.runChecks()
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		
	}
	
	func sceneWillEnterForeground(_ scene: UIScene) {
		
		//WalletConnectService.shared.connect()
		
		// Check system colors set correctly from beginning
		ThemeManager.shared.updateSystemInterfaceStyle()
		
		// Remove any old assets to avoid clogging up users device too much
		MediaProxyService.clearExpiredImages()
		
		// Remove any old 3D models
		DiskService.clearFiles(inFolder: "models", olderThanDays: 3) { _ in
			
		}
	}
	
	func sceneDidEnterBackground(_ scene: UIScene) {
		//WalletConnectService.shared.disconnect()
		
		// When entering background, cover the screen in a new window containing a nav controller and the login flow
		// They will auto trigger themselves based on `viewDidAppear` methods
		showPrivacyProtectionWindow()
		
		DispatchQueue.global(qos: .background).async {
			DependencyManager.shared.tzktClient.stopListeningForAccountChanges()
		}
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}
		
		handleDeeplink(url: url)
	}
	
	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			let url = userActivity.webpageURL else {
			return
		}
		
		handleDeeplink(url: url)
	}
	
	
	
	// MARK: - Non system functions
	
	func showPrivacyProtectionWindow() {
		/*
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "calling showPrivacyProtectionWindow"))
		
		guard !privacyProtectionWindowVisible else {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "can't continue showPrivacyProtectionWindow"))
			return
		}
		
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "continuing showPrivacyProtectionWindow"))
		privacyProtectionWindowVisible = true
		privacyProtectionWindow.rootViewController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() ?? UIViewController()
		privacyProtectionWindow.windowLevel = .alert + 1
		privacyProtectionWindow.alpha = 1
		privacyProtectionWindow.isHidden = false
		privacyProtectionWindow.makeKeyAndVisible()
		*/
		
		
		guard let login = loginVc, let currentWindow = UIApplication.shared.currentWindowIncludingSuspended, login.view.superview == nil else {
			return
		}
		
		DependencyManager.shared.loginActive = true
		currentWindow.addSubview(login.view)
		
		NSLayoutConstraint.activate([
			login.view.leadingAnchor.constraint(equalTo: currentWindow.leadingAnchor),
			login.view.trailingAnchor.constraint(equalTo: currentWindow.trailingAnchor),
			login.view.topAnchor.constraint(equalTo: currentWindow.topAnchor),
			login.view.bottomAnchor.constraint(equalTo: currentWindow.bottomAnchor)
		])
	}
	
	
	func hidePrivacyProtectionWindow() {
		/*
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "calling hidePrivacyProtectionWindow"))
		
		guard privacyProtectionWindowVisible else {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "can't continue hidePrivacyProtectionWindow"))
			return
		}
		
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "continuing hidePrivacyProtectionWindow"))
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.privacyProtectionWindow.alpha = 0
			
		} completion: { [weak self] finish in
			self?.privacyProtectionWindow.isHidden = true
			self?.privacyProtectionWindowVisible = false
			self?.dismissedPrivacyProtectionWindow = true
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "done animating hidePrivacyProtectionWindow"))
		}
		*/
		
		
		loginVc?.view.removeFromSuperview()
		DependencyManager.shared.loginActive = false
	}
	
	private func handleDeeplink(url: URL) {
		Logger.app.info("Attempting to handle deeplink \(url.absoluteString)")
		
		if url.absoluteString.prefix(10) == "kukai://wc" {
			let wc2URI = String(url.absoluteString.dropFirst(15)) // just strip off "kukai://wc?uri="
			handleWC(withURI: wc2URI)
		} else if url.absoluteString.prefix(28) == "https://connect.kukai.app/wc" {
			let wc2URI = String(url.absoluteString.dropFirst(33)) // just strip off "https://connect.kukai.app/wc?uri="
			handleWC(withURI: wc2URI)
		}
		else {
			CustomAuth.handle(url: url)
		}
	}
	
	private func handleWC(withURI uri: String) {
		var wc2URI = uri
		wc2URI = wc2URI.removingPercentEncoding ?? ""
		
		if let uri = try? WalletConnectURI(uriString: String(wc2URI)) {
			
			if WalletConnectService.shared.hasBeenSetup {
				WalletConnectService.shared.pairClient(uri: uri)
				
			} else {
				WalletConnectService.shared.deepLinkPairingToConnect = uri
			}
		}
	}
}

