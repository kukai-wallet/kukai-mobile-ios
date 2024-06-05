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
	public var privacyProtectionWindowVisible = false
	
	@Published var dismissedPrivacyProtectionWindow = false
	
	private var privacyProtectionWindow: UIWindow?
	
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let scene = (scene as? UIWindowScene) else { return }
		
		privacyProtectionWindow = UIWindow(windowScene: scene)
		WalletConnectService.shared.setup()
		
		scene.windows.forEach { window in
			window.overrideUserInterfaceStyle = ThemeManager.shared.currentInterfaceStyle()
		}
		
		if let url = connectionOptions.urlContexts.first?.url {
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
	
	
	
	// MARK: - Non system functions
	
	func showPrivacyProtectionWindow() {
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "calling showPrivacyProtectionWindow"))
		
		guard !privacyProtectionWindowVisible else {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "can't continue showPrivacyProtectionWindow"))
			return
		}
		
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "continuing showPrivacyProtectionWindow"))
		privacyProtectionWindowVisible = true
		privacyProtectionWindow?.rootViewController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() ?? UIViewController()
		privacyProtectionWindow?.windowLevel = .alert + 1
		privacyProtectionWindow?.alpha = 1
		privacyProtectionWindow?.isHidden = false
		privacyProtectionWindow?.makeKeyAndVisible()
	}
	
	
	func hidePrivacyProtectionWindow() {
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "calling hidePrivacyProtectionWindow"))
		
		guard privacyProtectionWindowVisible else {
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "can't continue hidePrivacyProtectionWindow"))
			return
		}
		
		SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "continuing hidePrivacyProtectionWindow"))
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.privacyProtectionWindow?.alpha = 0
			
		} completion: { [weak self] finish in
			self?.privacyProtectionWindow?.isHidden = true
			self?.privacyProtectionWindowVisible = false
			self?.dismissedPrivacyProtectionWindow = true
			SentrySDK.addBreadcrumb(Breadcrumb(level: .info, category: "kukai", message: "done animating hidePrivacyProtectionWindow"))
		}
	}
	
	private func handleDeeplink(url: URL) {
		Logger.app.info("Attempting to handle deeplink \(url.absoluteString)")
		
		if url.absoluteString.prefix(10) == "kukai://wc" {
			var wc2URI = String(url.absoluteString.dropFirst(15)) // just strip off "kukai://wc?uri="
			wc2URI = wc2URI.removingPercentEncoding ?? ""
			
			if let uri = try? WalletConnectURI(uriString: String(wc2URI)) {
				
				if WalletConnectService.shared.hasBeenSetup {
					WalletConnectService.shared.pairClient(uri: uri)
					
				} else {
					WalletConnectService.shared.deepLinkPairingToConnect = uri
				}
			}
		} else {
			CustomAuth.handle(url: url)
		}
	}
}
