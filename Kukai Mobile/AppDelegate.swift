//
//  AppDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		setAppearenceProxies()
		
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}
	
	func setAppearenceProxies() {
		
		// Hide back button text
		let barButtonAppearence = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
		let barButtonTextAttributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key.font: UIFont.systemFont(ofSize: 0.1),
			NSAttributedString.Key.foregroundColor: UIColor.clear
		]
		barButtonAppearence.setTitleTextAttributes(barButtonTextAttributes, for: .normal)
	}
}

