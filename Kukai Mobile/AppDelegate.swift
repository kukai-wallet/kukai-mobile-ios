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
	
	
	// Liquidity baking
	// Granadanet dex contract: 	KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5
	// Granadanet lq token:			KT1AafHA1C1vk959wvHWBispY9Y2f3fxBUUo
	// Granadanet tzBTC token:		KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn
	
	
	
	// Side nav
	//	- network switching
	// exchange tab
	//	- granada liquidity baking
	//	- Quipu swap
	
	
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Global appearenace proxy styles
		setAppearenceProxies()
		
		
		// Setup Sentry, but with Anonymous events
		do {
			let sentryOptions = try Options(dict: ["dsn": "https://53b9190ed8364ecc9b418dcc3493c506@o926227.ingest.sentry.io/5875459"])
			sentryOptions.beforeSend = { (event) -> Event? in
				
				// Scrub any identifiable data to keep users anonymous
				event.context?["app"]?.removeValue(forKey: "device_app_hash")
				event.user = nil
				
				return event
			}
			
			SentrySDK.start(options: sentryOptions)
			
		} catch (let error) {
			os_log(.error, log: .default, "Sentry throw an error: %@", "\(error)")
		}
		
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

