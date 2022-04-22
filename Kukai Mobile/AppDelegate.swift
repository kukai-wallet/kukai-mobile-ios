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
class AppDelegate: UIResponder, UIApplicationDelegate, ThemeManagerDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		setupTheme()
		
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
	
	
	
	// MARK: Theme
	
	func setupTheme() {
		ThemeManager.shared.setup(
			lightColors: [
				"background": UIColor("#E5E5E5"),
				"image-border": UIColor("#F1F1F1"),
				"modal-background": UIColor("#FFFFFF"),
				
				"primary-button-background": UIColor("#5862FF"),
				"primary-button-text": UIColor("#FFFFFF"),
				"secondary-button-background": UIColor("#F0F0F0"),
				"secondary-button-text": UIColor("#5862FF"),
				"tertiary-button-background": UIColor("#F1F1F1"),
				"tertiary-button-text": UIColor("#333333"),
				
				"text-link": UIColor("#465AFF"),
				"text-primary": UIColor("#1C1C1C"),
				"text-secondary": UIColor("#545454"),
				"text-tertiary": UIColor("#707070")
			],
			darkColors: [
				"background": UIColor("#424242"),
				"image-border": UIColor("#F0F0F0"),
				"modal-background": UIColor("#424242"),
				
				"primary-button-background": UIColor("#000000"),
				"primary-button-text": UIColor("#FFFFFF"),
				"secondary-button-background": UIColor("#7F7F7F"),
				"secondary-button-text": UIColor("#000000"),
				"tertiary-button-background": UIColor("#F1F1F1"),
				"tertiary-button-text": UIColor("#333333"),
				
				"text-link": UIColor("#465AFF"),
				"text-primary": UIColor("#FFFFFF"),
				"text-secondary": UIColor("#F0F0F0"),
				"text-tertiary": UIColor("#707070")
			],
			others: [
				"Red": ThemeManager.ThemeData(interfaceStyle: .light, namedColors: [
					"background": UIColor("#E41D1F"),
					"image-border": UIColor("#E41D1F"),
					"modal-background": UIColor("#FFFFFF"),
					
					"primary-button-background": UIColor("#5862FF"),
					"primary-button-text": UIColor("#FFFFFF"),
					"secondary-button-background": UIColor("#F0F0F0"),
					"secondary-button-text": UIColor("#5862FF"),
					"tertiary-button-background": UIColor("#F1F1F1"),
					"tertiary-button-text": UIColor("#333333"),
					
					"text-link": UIColor("#465AFF"),
					"text-primary": UIColor("#1C1C1C"),
					"text-secondary": UIColor("#545454"),
					"text-tertiary": UIColor("#707070")
				]),
				"Blue": ThemeManager.ThemeData(interfaceStyle: .light, namedColors: [
					"background": UIColor("#0F2DE4"),
					"image-border": UIColor("#0F2DE4"),
					"modal-background": UIColor("#FFFFFF"),
					
					"primary-button-background": UIColor("#5862FF"),
					"primary-button-text": UIColor("#FFFFFF"),
					"secondary-button-background": UIColor("#F0F0F0"),
					"secondary-button-text": UIColor("#5862FF"),
					"tertiary-button-background": UIColor("#F1F1F1"),
					"tertiary-button-text": UIColor("#333333"),
					
					"text-link": UIColor("#465AFF"),
					"text-primary": UIColor("#1C1C1C"),
					"text-secondary": UIColor("#545454"),
					"text-tertiary": UIColor("#707070")
				]),
			])
		
		ThemeManager.shared.delegate = self
		
		// Global appearenace proxy styles
		setAppearenceProxies()
	}
	
	func themeDidChange(to: String) {
		setAppearenceProxies()
	}
	
	func setAppearenceProxies() {
		
		// Change back button tint
		let barButtonAppearence = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
		barButtonAppearence.tintColor = UIColor(named: "text-primary")
	}
}

