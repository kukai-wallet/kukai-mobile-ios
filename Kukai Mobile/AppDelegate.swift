//
//  AppDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import Sentry
import os.log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		setupTheme()
		StorageService.runCleanupChecks()
		
		#if targetEnvironment(simulator)
			// If running on simulator, print documents directory to help with debugging
			if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
				print("Documents Directory: \(documentsPath) \n\n")
			}
		
		#else
			// If not running on simulator, Setup Sentry, but with Anonymous events
			SentrySDK.start { options in
				options.dsn = "https://6078bc46bd5c46e1aa6a416c8043f9f4@o1056238.ingest.sentry.io/4505443257024512"
				options.beforeSend = { (event) -> Event? in
					
					// Scrub any identifiable data to keep users anonymous
					event.context?["app"]?.removeValue(forKey: "device_app_hash")
					event.user = nil
				
					return event
				}
			}
		#endif
		
		// Airplay audio/video support
		application.beginReceivingRemoteControlEvents()
		
		return true
	}
	
	
	
	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
	}
	
	
	
	// MARK: Theme
	
	func setupTheme() {
		ThemeManager.shared.setup()
		
		// Global appearenace proxy styles
		setAppearenceProxies()
	}
	
	func setAppearenceProxies() {
		let navigationBarAppearance = UINavigationBarAppearance()
		navigationBarAppearance.configureWithOpaqueBackground()
		navigationBarAppearance.backgroundColor = UIColor.clear
		navigationBarAppearance.shadowColor = .clear
		navigationBarAppearance.titleTextAttributes = [
			NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2"),
			NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)
		]
		
		UINavigationBar.appearance().standardAppearance = navigationBarAppearance
		UINavigationBar.appearance().compactAppearance = navigationBarAppearance
		UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
		
		
		// Change back button tint
		let barButtonAppearence = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
		barButtonAppearence.tintColor = UIColor.colorNamed("BGB4")
		barButtonAppearence.setTitleTextAttributes([.foregroundColor: UIColor.clear, .font: UIFont.systemFont(ofSize: 1)], for: .normal)
	}
}
