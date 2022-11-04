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
				"Brand-100": UIColor("#F8F8FF"),
				"Brand-200": UIColor("#F2F3FF"),
				"Brand-300": UIColor("#E7E8FF"),
				"Brand-400": UIColor("#DBDDFF"),
				"Brand-500": UIColor("#D0D3FF"),
				"Brand-600": UIColor("#B9BDFF"),
				"Brand-700": UIColor("#ABB0FF"),
				"Brand-800": UIColor("#9298FF"),
				"Brand-900": UIColor("#848BFF"),
				"Brand-1000": UIColor("#6D75F4"),
				"Brand-1100": UIColor("#656DE5"),
				"Brand-1200": UIColor("#555CCA"),
				"Brand-1300": UIColor("#474DB0"),
				"Brand-1400": UIColor("#343994"),
				"Brand-1500": UIColor("#2A2E78"),
				"Brand-1600": UIColor("#20235E"),
				"Brand-1700": UIColor("#1E1F34"),
				
				"Grey-100": UIColor("#FFFFFF"),
				"Grey-200": UIColor("#F6F6FA"),
				"Grey-300": UIColor("#EFF0F9"),
				"Grey-400": UIColor("#E9EAF5"),
				"Grey-500": UIColor("#DFE0F0"),
				"Grey-600": UIColor("#D5D6E8"),
				"Grey-700": UIColor("#CDCEE5"),
				"Grey-800": UIColor("#BCBED4"),
				"Grey-900": UIColor("#A2A4BA"),
				"Grey-1000": UIColor("#86889D"),
				"Grey-1100": UIColor("#787A90"),
				"Grey-1200": UIColor("#696A80"),
				"Grey-1300": UIColor("#5C5E76"),
				"Grey-1400": UIColor("#4E5066"),
				"Grey-1500": UIColor("#3C3D50"),
				"Grey-1600": UIColor("#2D2E3F"),
				"Grey-1700": UIColor("#22222E"),
				"Grey-1800": UIColor("#1C1C27"),
				"Grey-1900": UIColor("#14141D"),
				"Grey-2000": UIColor("#000000"),
			],
			darkColors: [
				"Brand-100": UIColor("#F8F8FF"),
				"Brand-200": UIColor("#F2F3FF"),
				"Brand-300": UIColor("#E7E8FF"),
				"Brand-400": UIColor("#DBDDFF"),
				"Brand-500": UIColor("#D0D3FF"),
				"Brand-600": UIColor("#B9BDFF"),
				"Brand-700": UIColor("#ABB0FF"),
				"Brand-800": UIColor("#9298FF"),
				"Brand-900": UIColor("#848BFF"),
				"Brand-1000": UIColor("#6D75F4"),
				"Brand-1100": UIColor("#656DE5"),
				"Brand-1200": UIColor("#555CCA"),
				"Brand-1300": UIColor("#474DB0"),
				"Brand-1400": UIColor("#343994"),
				"Brand-1500": UIColor("#2A2E78"),
				"Brand-1600": UIColor("#20235E"),
				"Brand-1700": UIColor("#1E1F34"),
				
				"Grey-100": UIColor("#FFFFFF"),
				"Grey-200": UIColor("#F6F6FA"),
				"Grey-300": UIColor("#EFF0F9"),
				"Grey-400": UIColor("#E9EAF5"),
				"Grey-500": UIColor("#DFE0F0"),
				"Grey-600": UIColor("#D5D6E8"),
				"Grey-700": UIColor("#CDCEE5"),
				"Grey-800": UIColor("#BCBED4"),
				"Grey-900": UIColor("#A2A4BA"),
				"Grey-1000": UIColor("#86889D"),
				"Grey-1100": UIColor("#787A90"),
				"Grey-1200": UIColor("#696A80"),
				"Grey-1300": UIColor("#5C5E76"),
				"Grey-1400": UIColor("#4E5066"),
				"Grey-1500": UIColor("#3C3D50"),
				"Grey-1600": UIColor("#2D2E3F"),
				"Grey-1700": UIColor("#22222E"),
				"Grey-1800": UIColor("#1C1C27"),
				"Grey-1900": UIColor("#14141D"),
				"Grey-2000": UIColor("#000000"),
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
		let navigationBarAppearance = UINavigationBarAppearance()
		navigationBarAppearance.configureWithOpaqueBackground()
		navigationBarAppearance.backgroundColor = UIColor.clear
		navigationBarAppearance.shadowColor = .clear
		
		UINavigationBar.appearance().standardAppearance = navigationBarAppearance
		UINavigationBar.appearance().compactAppearance = navigationBarAppearance
		UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
		
		
		// Change back button tint
		//let barButtonAppearence = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
		//barButtonAppearence.tintColor = UIColor(named: "text-primary")
	}
}

