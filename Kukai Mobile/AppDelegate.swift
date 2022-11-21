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
				"Brand100": UIColor("#F8F8FF"),
				"Brand200": UIColor("#F2F3FF"),
				"Brand300": UIColor("#E7E8FF"),
				"Brand400": UIColor("#DBDDFF"),
				"Brand500": UIColor("#D0D3FF"),
				"Brand600": UIColor("#B9BDFF"),
				"Brand700": UIColor("#ABB0FF"),
				"Brand800": UIColor("#9298FF"),
				"Brand900": UIColor("#848BFF"),
				"Brand1000": UIColor("#6D75F4"),
				"Brand1100": UIColor("#656DE6"),
				"Brand1200": UIColor("#555CCA"),
				"Brand1300": UIColor("#474DB0"),
				"Brand1400": UIColor("#343994"),
				"Brand1500": UIColor("#2A2E78"),
				"Brand1600": UIColor("#20235E"),
				"Brand1700": UIColor("#1E1F34"),
				
				"Grey100": UIColor("#FFFFFF"),
				"Grey200": UIColor("#F6F6FA"),
				"Grey300": UIColor("#EFF0F9"),
				"Grey400": UIColor("#E9EAF5"),
				"Grey500": UIColor("#DFE0F0"),
				"Grey600": UIColor("#D5D6E8"),
				"Grey700": UIColor("#CDCEE5"),
				"Grey800": UIColor("#BCBED4"),
				"Grey900": UIColor("#A2A4BA"),
				"Grey1000": UIColor("#86889D"),
				"Grey1100": UIColor("#787A90"),
				"Grey1200": UIColor("#696A80"),
				"Grey1300": UIColor("#5C5E76"),
				"Grey1400": UIColor("#4E5066"),
				"Grey1500": UIColor("#3C3D50"),
				"Grey1600": UIColor("#2D2E3F"),
				"Grey1700": UIColor("#22222E"),
				"Grey1800": UIColor("#1C1C27"),
				"Grey1900": UIColor("#14141D"),
				"Grey2000": UIColor("#000000"),
				
				"Caution100": UIColor("#FFDEE8"),
				"Caution200": UIColor("#FFD1DF"),
				"Caution300": UIColor("#FFB1C9"),
				"Caution400": UIColor("#FF96B5"),
				"Caution500": UIColor("#FF89AC"),
				"Caution600": UIColor("#FF759E"),
				"Caution700": UIColor("#F25D8A"),
				"Caution800": UIColor("#E45882"),
				"Caution900": UIColor("#D34C74"),
				"Caution1000": UIColor("#C6436A"),
				"Caution1100": UIColor("#B5385D"),
				"Caution1200": UIColor("#9F274B"),
				"Caution1300": UIColor("#941E41"),
				"Caution1400": UIColor("#7E1635"),
				"Caution1500": UIColor("#710A29"),
				"Caution1600": UIColor("#56061E"),
				"Caution1700": UIColor("#370011"),
				
				"Positive100": UIColor("#D9FFE8"),
				"Positive200": UIColor("#BBFFD6"),
				"Positive300": UIColor("#A1FFC7"),
				"Positive400": UIColor("#7BFFB0"),
				"Positive500": UIColor("#56F997"),
				"Positive600": UIColor("#39E87F"),
				"Positive700": UIColor("#1FD568"),
				"Positive800": UIColor("#0FC357"),
				"Positive900": UIColor("#09AE4B"),
				"Positive1000": UIColor("#0A9D45"),
				"Positive1100": UIColor("#0A8F3F"),
				"Positive1200": UIColor("#097B37"),
				"Positive1300": UIColor("#086B30"),
				"Positive1400": UIColor("#075D2A"),
				"Positive1500": UIColor("#064B22"),
				"Positive1600": UIColor("#053A1A"),
				"Positive1700": UIColor("#012811"),
				
				"YellowAccent100": UIColor("#FFF8E4"),
				"YellowAccent200": UIColor("#FFF0C9"),
				"YellowAccent300": UIColor("#FFE8AE"),
				"YellowAccent400": UIColor("#FFE196"),
				"YellowAccent500": UIColor("#FFDC82"),
				"YellowAccent600": UIColor("#FFD66C"),
				"YellowAccent700": UIColor("#F1CC6E"),
				"YellowAccent800": UIColor("#DDBD6A"),
				"YellowAccent900": UIColor("#CCAF64"),
				"YellowAccent1000": UIColor("#BFA35B"),
				"YellowAccent1100": UIColor("#B89845"),
				"YellowAccent1200": UIColor("#AF8D34"),
				"YellowAccent1300": UIColor("#9E7C22"),
				"YellowAccent1400": UIColor("#8B6B15"),
				"YellowAccent1500": UIColor("#76580A"),
				"YellowAccent1600": UIColor("#584104"),
				"YellowAccent1700": UIColor("#382902"),
			],
			darkColors: [
				"Brand100": UIColor("#F8F8FF"),
				"Brand200": UIColor("#F2F3FF"),
				"Brand300": UIColor("#E7E8FF"),
				"Brand400": UIColor("#DBDDFF"),
				"Brand500": UIColor("#D0D3FF"),
				"Brand600": UIColor("#B9BDFF"),
				"Brand700": UIColor("#ABB0FF"),
				"Brand800": UIColor("#9298FF"),
				"Brand900": UIColor("#848BFF"),
				"Brand1000": UIColor("#6D75F4"),
				"Brand1100": UIColor("#656DE6"),
				"Brand1200": UIColor("#555CCA"),
				"Brand1300": UIColor("#474DB0"),
				"Brand1400": UIColor("#343994"),
				"Brand1500": UIColor("#2A2E78"),
				"Brand1600": UIColor("#20235E"),
				"Brand1700": UIColor("#1E1F34"),
				
				"Grey100": UIColor("#FFFFFF"),
				"Grey200": UIColor("#F6F6FA"),
				"Grey300": UIColor("#EFF0F9"),
				"Grey400": UIColor("#E9EAF5"),
				"Grey500": UIColor("#DFE0F0"),
				"Grey600": UIColor("#D5D6E8"),
				"Grey700": UIColor("#CDCEE5"),
				"Grey800": UIColor("#BCBED4"),
				"Grey900": UIColor("#A2A4BA"),
				"Grey1000": UIColor("#86889D"),
				"Grey1100": UIColor("#787A90"),
				"Grey1200": UIColor("#696A80"),
				"Grey1300": UIColor("#5C5E76"),
				"Grey1400": UIColor("#4E5066"),
				"Grey1500": UIColor("#3C3D50"),
				"Grey1600": UIColor("#2D2E3F"),
				"Grey1700": UIColor("#22222E"),
				"Grey1800": UIColor("#1C1C27"),
				"Grey1900": UIColor("#14141D"),
				"Grey2000": UIColor("#000000"),
				
				"Caution100": UIColor("#FFDEE8"),
				"Caution200": UIColor("#FFD1DF"),
				"Caution300": UIColor("#FFB1C9"),
				"Caution400": UIColor("#FF96B5"),
				"Caution500": UIColor("#FF89AC"),
				"Caution600": UIColor("#FF759E"),
				"Caution700": UIColor("#F25D8A"),
				"Caution800": UIColor("#E45882"),
				"Caution900": UIColor("#D34C74"),
				"Caution1000": UIColor("#C6436A"),
				"Caution1100": UIColor("#B5385D"),
				"Caution1200": UIColor("#9F274B"),
				"Caution1300": UIColor("#941E41"),
				"Caution1400": UIColor("#7E1635"),
				"Caution1500": UIColor("#710A29"),
				"Caution1600": UIColor("#56061E"),
				"Caution1700": UIColor("#370011"),
				
				"Positive100": UIColor("#D9FFE8"),
				"Positive200": UIColor("#BBFFD6"),
				"Positive300": UIColor("#A1FFC7"),
				"Positive400": UIColor("#7BFFB0"),
				"Positive500": UIColor("#56F997"),
				"Positive600": UIColor("#39E87F"),
				"Positive700": UIColor("#1FD568"),
				"Positive800": UIColor("#0FC357"),
				"Positive900": UIColor("#09AE4B"),
				"Positive1000": UIColor("#0A9D45"),
				"Positive1100": UIColor("#0A8F3F"),
				"Positive1200": UIColor("#097B37"),
				"Positive1300": UIColor("#086B30"),
				"Positive1400": UIColor("#075D2A"),
				"Positive1500": UIColor("#064B22"),
				"Positive1600": UIColor("#053A1A"),
				"Positive1700": UIColor("#012811"),
				
				"YellowAccent100": UIColor("#FFF8E4"),
				"YellowAccent200": UIColor("#FFF0C9"),
				"YellowAccent300": UIColor("#FFE8AE"),
				"YellowAccent400": UIColor("#FFE196"),
				"YellowAccent500": UIColor("#FFDC82"),
				"YellowAccent600": UIColor("#FFD66C"),
				"YellowAccent700": UIColor("#F1CC6E"),
				"YellowAccent800": UIColor("#DDBD6A"),
				"YellowAccent900": UIColor("#CCAF64"),
				"YellowAccent1000": UIColor("#BFA35B"),
				"YellowAccent1100": UIColor("#B89845"),
				"YellowAccent1200": UIColor("#AF8D34"),
				"YellowAccent1300": UIColor("#9E7C22"),
				"YellowAccent1400": UIColor("#8B6B15"),
				"YellowAccent1500": UIColor("#76580A"),
				"YellowAccent1600": UIColor("#584104"),
				"YellowAccent1700": UIColor("#382902"),
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
		navigationBarAppearance.titleTextAttributes = [
			NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Grey200"),
			NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)
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

