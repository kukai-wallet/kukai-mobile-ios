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
		ThemeManager.shared.setup(
			lightColors: [
				
				// Default Text
				"Txt0": UIColor("#000000"),
				"Txt2": UIColor("#1C1C27"),
				"Txt4": UIColor("#2D2E3F"),
				"Txt6": UIColor("#4E5066"),
				"Txt8": UIColor("#696A80"),
				"Txt10": UIColor("#86889D"),
				"Txt12": UIColor("#BCBED4"),
				"Txt14": UIColor("#D5D6E8"),
				"TxtMenuContext": UIColor("#2D2E3F"),
				
				// Button Text
				
				// Coloured Text
				"TxtB2": UIColor("#555CCA"),
				"TxtB4": UIColor("#5C65F0"),
				"TxtB6": UIColor("#6D75F4"),
				"TxtB8": UIColor("#A4A8F1"),
				"TxtAlert2": UIColor("#9F274B"),
				"TxtAlert4": UIColor("#D34C74"),
				"TxtAlert6": UIColor("#FF759E"),
				"TxtGood2": UIColor("#097B37"),
				"TxtGood4": UIColor("#09AE4B"),
				"TxtGood6": UIColor("#39E87F"),
				"TxtB-alt2": UIColor("#AF8D34"),
				"TxtB-alt4": UIColor("#CCAF64"),
				"TxtB-alt6": UIColor("#FFD66C"),
				
				// Buttons background
				
				// Background
				"BG0": UIColor("#FFFFFF"),
				"BG2": UIColor("#F6F6FA"),
				"BG4": UIColor("#E9EAF5"),
				"BG6": UIColor("#D5D6E8"),
				"BG8": UIColor("#BCBED4"),
				"BG10": UIColor("#86889D"),
				"BG12": UIColor("#696A80"),
				"BGB0": UIColor("#B9BDFF"),
				"BGB2": UIColor("#9298FF"),
				"BGB4": UIColor("#6D75F4"),
				"BGB6": UIColor("#6D75F4"),
				"BGB8": UIColor("#343994"),
				"BGGood2": UIColor("#39E87F"),
				"BGGood4": UIColor("#09AE4B"),
				"BGGood6": UIColor("#097B37"),
				"BGAlert2": UIColor("#FF759E"),
				"BGAlert4": UIColor("#D34C74"),
				"BGAlert6": UIColor("#9F274B"),
				
				// Gradient
				"gradBgFull-1": UIColor("#FFFFFF"),
				"gradBgFull-2": UIColor("#FAFAFF"),
				"gradBgFull-3": UIColor("#FAFAFF"),
				"gradTabBar-1": UIColor("#FFFFFF"),
				"gradTabBar-2": UIColor("#DBDCE8"),
				"gradPanelRows-1": UIColor("#DDDDF0", alpha: 0.4),
				"gradPanelRows-2": UIColor("#E4E4F1", alpha: 0.15),
				
				"gradNavBarPanels-1": UIColor("#D5D6E8", alpha: 0.25),
				"gradNavBarPanels-2": UIColor("#D5D6E8", alpha: 0.1),
				"gradStroke_NavBarPanels-1": UIColor("#D5D6E8", alpha: 1),
				"gradStroke_NavBarPanels-2": UIColor("#9EA2F4", alpha: 0.51),
			],
			darkColors: [
				
				// Default Text
				"Txt0": UIColor("#FFFFFF"),
				"Txt2": UIColor("#F6F6FA"),
				"Txt4": UIColor("#E9EAF5"),
				"Txt6": UIColor("#D5D6E8"),
				"Txt8": UIColor("#BCBED5"),
				"Txt10": UIColor("#86889D"),
				"Txt12": UIColor("#696A80"),
				"Txt14": UIColor("#4E5066"),
				"TxtMenuContext": UIColor("#E9EAF5"),
				
				// Button Text
				
				// Coloured Text
				"TxtB2": UIColor("#B9BDFF"),
				"TxtB4": UIColor("#9298FF"),
				"TxtB6": UIColor("#6D75F4"),
				"TxtB8": UIColor("#555CCA"),
				"TxtAlert2": UIColor("#FF759E"),
				"TxtAlert4": UIColor("#D34C74"),
				"TxtAlert6": UIColor("#9F274B"),
				"TxtGood2": UIColor("#39E87F"),
				"TxtGood4": UIColor("#09AE4B"),
				"TxtGood6": UIColor("#097B37"),
				"TxtB-alt2": UIColor("#FFD66C"),
				"TxtB-alt4": UIColor("#CCAF64"),
				"TxtB-alt6": UIColor("#AF8D34"),
				
				// Buttons background
				
				// Background
				"BG0": UIColor("#000000"),
				"BG2": UIColor("#14141D"),
				"BG4": UIColor("#2D2E3F"),
				"BG6": UIColor("#4E5066"),
				"BG8": UIColor("#696A80"),
				"BG10": UIColor("#86889D"),
				"BG12": UIColor("#BCBED4"),
				"BGB0": UIColor("#343994"),
				"BGB2": UIColor("#555CCA"),
				"BGB4": UIColor("#6D75F4"),
				"BGB6": UIColor("#9298FF"),
				"BGB8": UIColor("#B9BDFF"),
				"BGGood2": UIColor("#097B37"),
				"BGGood4": UIColor("#09AE4B"),
				"BGGood6": UIColor("#39E87F"),
				"BGAlert2": UIColor("#9F274B"),
				"BGAlert4": UIColor("#D34C74"),
				"BGAlert6": UIColor("#FF759E"),
				
				// Gradient
				"gradBgFull-1": UIColor("#212234"),
				"gradBgFull-2": UIColor("#14141D"),
				"gradBgFull-3": UIColor("#14141D"),
				"gradTabBar-1": UIColor("#22222E"),
				"gradTabBar-2": UIColor("#181820"),
				"gradPanelRows-1": UIColor("#C1C1D9", alpha: 0.1),
				"gradPanelRows-2": UIColor("#D3D3E7", alpha: 0.05),
				
				"gradNavBarPanels-1": UIColor("#181826", alpha: 0.25),
				"gradNavBarPanels-2": UIColor("#181826", alpha: 0.1),
				"gradStroke_NavBarPanels-1": UIColor("#3A3D63", alpha: 1),
				"gradStroke_NavBarPanels-2": UIColor("#5861DE", alpha: 0.51),
			],
			others: [
				"Red": ThemeManager.ThemeData(interfaceStyle: .light, namedColors: [
					"background": UIColor("#E41D1F"),
					"image-border": UIColor("#E41D1F"),
					"modal-background": UIColor("#FFFFFF")
				]),
				"Blue": ThemeManager.ThemeData(interfaceStyle: .light, namedColors: [
					"background": UIColor("#0F2DE4"),
					"image-border": UIColor("#0F2DE4"),
					"modal-background": UIColor("#FFFFFF")
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
		navigationBarAppearance.titleTextAttributes = [
			NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2"),
			NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 21)
		]
		
		UINavigationBar.appearance().standardAppearance = navigationBarAppearance
		UINavigationBar.appearance().compactAppearance = navigationBarAppearance
		UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
		
		
		// Change back button tint
		//let barButtonAppearence = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
		//barButtonAppearence.tintColor = UIColor.colorNamed("Brand1100")
		//barButtonAppearence.setTitleTextAttributes([.foregroundColor: UIColor.clear, .font: UIFont.systemFont(ofSize: 1)], for: .normal)
	}
}

