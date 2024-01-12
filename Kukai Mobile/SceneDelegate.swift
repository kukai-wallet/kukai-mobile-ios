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
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var firstLoad = true
	
	private var privacyProtectionWindow: UIWindow?


	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let scene = (scene as? UIWindowScene) else { return }
		
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
	}

	func sceneWillResignActive(_ scene: UIScene) {
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Check system colors set correctly from beginning
		ThemeManager.shared.updateSystemInterfaceStyle()
		
		// Remove any old assets to avoid clogging up users device too much
		MediaProxyService.clearExpiredImages()
	}
	
	func sceneDidEnterBackground(_ scene: UIScene) {
		
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
		guard let windowScene = self.window?.windowScene else {
			return
		}
		
		privacyProtectionWindow = UIWindow(windowScene: windowScene)
		privacyProtectionWindow?.rootViewController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() ?? UIViewController()
		privacyProtectionWindow?.windowLevel = .alert + 1
		privacyProtectionWindow?.makeKeyAndVisible()
	}
	
	
	func hidePrivacyProtectionWindow() {
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.privacyProtectionWindow?.alpha = 0
			
		} completion: { [weak self] finish in
			self?.privacyProtectionWindow = nil
		}
	}
	
	private func handleDeeplink(url: URL) {
		Logger.app.info("Attempting to handle deeplink \(url.absoluteString)")
		
		if url.absoluteString.prefix(10) == "kukai://wc" {
			var wc2URI = String(url.absoluteString.dropFirst(15)) // just strip off "kukai://wc?uri="
			wc2URI = wc2URI.removingPercentEncoding ?? ""
			
			if let uri = WalletConnectURI(string: String(wc2URI)) {
				
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
