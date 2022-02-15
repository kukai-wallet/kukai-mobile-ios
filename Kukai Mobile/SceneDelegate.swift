//
//  SceneDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import CustomAuth
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	
	private var privacyProtectionWindow: UIWindow?


	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }
	}

	func sceneDidDisconnect(_ scene: UIScene) {
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
	}

	func sceneWillResignActive(_ scene: UIScene) {
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		
		// When entering background, cover the screen in a new window containing a nav controller and the login flow
		// They will auto trigger themselves based on `viewDidAppear` methods
		showPrivacyProtectionWindow()
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}
		
		CustomAuth.handle(url: url)
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
}

