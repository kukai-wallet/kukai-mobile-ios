//
//  SceneDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import TorusSwiftDirectSDK
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
		transitionPrivacyProtectionToLogin()
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		showPrivacyProtectionWindow()
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}
		
		TorusSwiftDirectSDK.handle(url: url)
	}
	
	
	
	
	
	// MARK: - Non system functions
	
	func showPrivacyProtectionWindow() {
		guard let windowScene = self.window?.windowScene else {
			return
		}
		
		privacyProtectionWindow = UIWindow(windowScene: windowScene)
		privacyProtectionWindow?.rootViewController = UIStoryboard.multitaskingCoverViewController()
		privacyProtectionWindow?.windowLevel = .alert + 1
		privacyProtectionWindow?.makeKeyAndVisible()
	}
	
	func transitionPrivacyProtectionToLogin() {
		guard let pWindow = privacyProtectionWindow else {
			os_log("Can't find multitasking window", log: .default, type: .debug)
			return
		}
		
		pWindow.rootViewController = UIStoryboard.loginViewController()
		
		let options: UIView.AnimationOptions = .transitionCrossDissolve
		UIView.transition(with: pWindow, duration: 0.3, options: options, animations: {}, completion: nil)
	}
	
	func hidePrivacyProtectionWindow() {
		guard let pWindow = privacyProtectionWindow else {
			os_log("Can't find multitasking window", log: .default, type: .debug)
			return
		}
		
		UIView.animate(withDuration: 0.3) {
			pWindow.alpha = 0
			
		} completion: { [weak self] finish in
			self?.privacyProtectionWindow = nil
		}

	}
}

