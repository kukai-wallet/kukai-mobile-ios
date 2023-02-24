//
//  AppDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import Sentry
import WalletConnectNetworking
import WalletConnectPairing
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
		
		// Airplay audio/video support
		application.beginReceivingRemoteControlEvents()
		
		
		// Wallet connect
		Networking.configure(projectId: "97f804b46f0db632c52af0556586a5f3", socketFactory: NativeSocketFactory())
		let metadata = AppMetadata(name: "Kukai iOS",
								   description: "Kukai iOS",
								   url: "https://wallet.kukai.app",
								   icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
								   redirect: AppMetadata.Redirect(native: "kukai://app", universal: nil))
		Pair.configure(metadata: metadata)
		
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
				"TxtBtnPrim1": UIColor("#FFFFFF"),
				"TxtBtnPrim2": UIColor("#FFFFFF"),
				"TxtBtnPrim3": UIColor("#FFFFFF"),
				"TxtBtnPrim4": UIColor("#F6F6FA"),
				"TxtBtnSec1": UIColor("#F6F6FA"),
				"TxtBtnSec2": UIColor("#FFFFFF"),
				"TxtBtnSec3": UIColor("#FFFFFF"),
				"TxtBtnSec4": UIColor("#FFFFFF"),
				"TxtBtnTer1": UIColor("#F6F6FA"),
				"TxtBtnTer2": UIColor("#FFFFFF"),
				"TxtBtnTer3": UIColor("#FFFFFF"),
				"TxtBtnTer4": UIColor("#F6F6FA"),
				"TxtBtnMicroB1": UIColor("#6D75F4"),
				"TxtBtnMicroB2": UIColor("#6D75F4"),
				"TxtBtnMicroB3": UIColor("#6D75F4"),
				"TxtBtnMicroB4": UIColor("#6D75F4"),
				"TxtBtnMicro1": UIColor("#86889D"),
				"TxtBtnMicro2": UIColor("#86889D"),
				"TxtBtnMicro3": UIColor("#86889D"),
				"TxtBtnMicro4": UIColor("#86889D"),
				"TxtBtnSlider1": UIColor("#F6F6FA"),
				"TxtBtnSlider2": UIColor("#F6F6FA"),
				
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
				"BtnPrim-1": UIColor("#626AED"),
				"BtnPrim-2": UIColor("#862AFC"),
				"BtnSec1": UIColor("#000000", alpha: 0.2),
				"BtnSec2": UIColor("#000000", alpha: 0.2),
				"BtnSec3": UIColor("#000000", alpha: 0.2),
				"BtnSec4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeSec1": UIColor("#6D75F4"),
				"BtnStrokeSec2": UIColor("#6D75F4"),
				"BtnStrokeSec3": UIColor("#6D75F4"),
				"BtnStrokeSec4": UIColor("#6D75F4"),
				"BtnStrokeSecSel": UIColor("#4E5066"),
				"BtnTer1": UIColor("#000000", alpha: 0.2),
				"BtnTer2": UIColor("#000000", alpha: 0.2),
				"BtnTer3": UIColor("#000000", alpha: 0.2),
				"BtnTer4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeTer1-1": UIColor("#626AED"),
				"BtnStrokeTer1-2": UIColor("#862AFC"),
				"BtnMicro1": UIColor("#22222E"),
				"BtnMicro2": UIColor("#22222E"),
				"BtnMicro3": UIColor("#22222E"),
				"BtnMicro4": UIColor("#22222E"),
				"BtnStrokeMicro1": UIColor("#3E3F50"),
				"BtnStrokeMicro2": UIColor("#3E3F50"),
				"BtnStrokeMicro3": UIColor("#3E3F50"),
				"BtnStrokeMicro4": UIColor("#3E3F50"),
				"BtnMicroB1": UIColor("#14141D"),
				"BtnMicroB2": UIColor("#14141D"),
				"BtnMicroB3": UIColor("#14141D"),
				"BtnMicroB4": UIColor("#14141D"),
				"BtnStrokeMicroB1": UIColor("#343994"),
				"BtnStrokeMicroB2": UIColor("#343994"),
				"BtnStrokeMicroB3": UIColor("#343994"),
				"BtnStrokeMicroB4": UIColor("#343994"),
				"BGBtn_Slider": UIColor("#4954ff", alpha: 0.07),
				"BGBtn_SliderFill": UIColor("#6d75f4", alpha: 0.25),
				
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
				"BGB-alt2": UIColor("#AF8D34"),
				"BGB-alt4": UIColor("#CCAF64"),
				"BGB-alt6": UIColor("#FFD66C"),
				"BGMenuContext": UIColor("#2D2E3F"),
				"LineMenuContext": UIColor("#3C3D50"),
				"BGInputs": UIColor("#2D2E3F"),
				"BGPanelExpand": UIColor("#1E1F34", alpha: 0.5),
				"BGInsets": UIColor("#14141D"),
				"BGMenuInsets": UIColor("#2D2E3F"),
				"BGMenu": UIColor("#22222E"),
				"BGBCallout": UIColor("#343994"),
				"BGSeeds": UIColor("#2D2E3F"),
				"BGSegPickOff": UIColor("#2D2E3F"),
				"BGSegPickOn": UIColor("#4E5066"),
				"BGBatchActivity": UIColor("#122446", alpha: 0.6),
				"BGToastDark": UIColor("#696A80"),
				"StrokeToastDark": UIColor("#787A90"),
				"BGToastAlertDark": UIColor("#7E1635"),
				"StrokeToastAlertDark": UIColor("#941E41"),
				"BGToastNeutralDark": UIColor("#2D2E3F"),
				"StrokeToastNeutralDark": UIColor("#3C3D50"),
				"TintGeneral": UIColor("#000000", alpha: 0.75),
				"TintContext": UIColor("#000000", alpha: 0.2),
				
				// Gradient
				"gradBgFull-1": UIColor("#F2F3FC"),
				"gradBgFull-2": UIColor("#F2F3FC"),
				"gradBgFull-3": UIColor("#F2F3FC"),
				"gradTabBar-1": UIColor("#FFFFFF"),
				"gradTabBar-2": UIColor("#DBDCE8"),
				"gradPanelRows-1": UIColor("#FFFFFF", alpha: 0.84),
				"gradPanelRows-2": UIColor("#FFFFFF", alpha: 0.53),
				"gradNavBarPanels-1": UIColor("#F5F5FF"),
				"gradNavBarPanels-2": UIColor("#F8F8FD"),
				"gradStroke_NavBarPanels-1": UIColor("#BCBDD1", alpha: 1),
				"gradStroke_NavBarPanels-2": UIColor("#B8BAD6", alpha: 0.5),
				"gradPanelAttributes-1": UIColor("#181826", alpha: 0.5),
				"gradPanelAttributes-2": UIColor("#181826", alpha: 0.2),
				"gradSliderCircle-1": UIColor("#FFFFFF"),
				"gradSliderCircle-2": UIColor("#9b9cb4"),
				"gradStrokeSlider-1": UIColor("#3F427E"),
				"gradStrokeSlider-2": UIColor("#464A8B"),
				"gradExpBorderTop-1": UIColor("#777FEE"),
				"gradExpBorderTop-2": UIColor("#858CED"),
				"gradExpBorderMiddle-1": UIColor("#858CED"),
				"gradExpBorderMiddle-2": UIColor("#858CED"),
				"gradExpBorderBottom-1": UIColor("#858CED"),
				"gradExpBorderBottom-2": UIColor("#C5C8FF"),
				"gradGraphToken-1": UIColor("#555CCA", alpha: 0.48),
				"gradGraphToken-2": UIColor("#555CCA", alpha: 0),
				"gradUnconfirmed-1": UIColor("#414164", alpha: 0.22),
				"gradUnconfirmed-2": UIColor("#353555", alpha: 0.15),
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
				"TxtBtnPrim1": UIColor("#FFFFFF"),
				"TxtBtnPrim2": UIColor("#FFFFFF"),
				"TxtBtnPrim3": UIColor("#FFFFFF"),
				"TxtBtnPrim4": UIColor("#F6F6FA"),
				"TxtBtnSec1": UIColor("#F6F6FA"),
				"TxtBtnSec2": UIColor("#FFFFFF"),
				"TxtBtnSec3": UIColor("#FFFFFF"),
				"TxtBtnSec4": UIColor("#FFFFFF"),
				"TxtBtnTer1": UIColor("#F6F6FA"),
				"TxtBtnTer2": UIColor("#FFFFFF"),
				"TxtBtnTer3": UIColor("#FFFFFF"),
				"TxtBtnTer4": UIColor("#F6F6FA"),
				"TxtBtnMicroB1": UIColor("#6D75F4"),
				"TxtBtnMicroB2": UIColor("#6D75F4"),
				"TxtBtnMicroB3": UIColor("#6D75F4"),
				"TxtBtnMicroB4": UIColor("#6D75F4"),
				"TxtBtnMicro1": UIColor("#86889D"),
				"TxtBtnMicro2": UIColor("#86889D"),
				"TxtBtnMicro3": UIColor("#86889D"),
				"TxtBtnMicro4": UIColor("#86889D"),
				"TxtBtnSlider1": UIColor("#F6F6FA"),
				"TxtBtnSlider2": UIColor("#F6F6FA"),
				
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
				"BtnPrim-1": UIColor("#626AED"),
				"BtnPrim-2": UIColor("#862AFC"),
				"BtnSec1": UIColor("#000000", alpha: 0.2),
				"BtnSec2": UIColor("#000000", alpha: 0.2),
				"BtnSec3": UIColor("#000000", alpha: 0.2),
				"BtnSec4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeSec1": UIColor("#6D75F4"),
				"BtnStrokeSec2": UIColor("#6D75F4"),
				"BtnStrokeSec3": UIColor("#6D75F4"),
				"BtnStrokeSec4": UIColor("#6D75F4"),
				"BtnStrokeSecSel": UIColor("#4E5066"),
				"BtnTer1": UIColor("#000000", alpha: 0.2),
				"BtnTer2": UIColor("#000000", alpha: 0.2),
				"BtnTer3": UIColor("#000000", alpha: 0.2),
				"BtnTer4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeTer1-1": UIColor("#626AED"),
				"BtnStrokeTer1-2": UIColor("#862AFC"),
				"BtnMicro1": UIColor("#22222E"),
				"BtnMicro2": UIColor("#22222E"),
				"BtnMicro3": UIColor("#22222E"),
				"BtnMicro4": UIColor("#22222E"),
				"BtnStrokeMicro1": UIColor("#3E3F50"),
				"BtnStrokeMicro2": UIColor("#3E3F50"),
				"BtnStrokeMicro3": UIColor("#3E3F50"),
				"BtnStrokeMicro4": UIColor("#3E3F50"),
				"BtnMicroB1": UIColor("#14141D"),
				"BtnMicroB2": UIColor("#14141D"),
				"BtnMicroB3": UIColor("#14141D"),
				"BtnMicroB4": UIColor("#14141D"),
				"BtnStrokeMicroB1": UIColor("#343994"),
				"BtnStrokeMicroB2": UIColor("#343994"),
				"BtnStrokeMicroB3": UIColor("#343994"),
				"BtnStrokeMicroB4": UIColor("#343994"),
				"BGBtn_Slider": UIColor("#4954ff", alpha: 0.07),
				"BGBtn_SliderFill": UIColor("#6d75f4", alpha: 0.25),
				
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
				"BGB-alt2": UIColor("#AF8D34"),
				"BGB-alt4": UIColor("#CCAF64"),
				"BGB-alt6": UIColor("#FFD66C"),
				"BGMenuContext": UIColor("#2D2E3F"),
				"LineMenuContext": UIColor("#3C3D50"),
				"BGInputs": UIColor("#2D2E3F"),
				"BGPanelExpand": UIColor("#1E1F34", alpha: 0.5),
				"BGInsets": UIColor("#14141D"),
				"BGMenuInsets": UIColor("#2D2E3F"),
				"BGMenu": UIColor("#22222E"),
				"BGBCallout": UIColor("#343994"),
				"BGSeeds": UIColor("#2D2E3F"),
				"BGSegPickOff": UIColor("#2D2E3F"),
				"BGSegPickOn": UIColor("#4E5066"),
				"BGBatchActivity": UIColor("#122446", alpha: 0.6),
				"BGToastDark": UIColor("#696A80"),
				"StrokeToastDark": UIColor("#787A90"),
				"BGToastAlertDark": UIColor("#7E1635"),
				"StrokeToastAlertDark": UIColor("#941E41"),
				"BGToastNeutralDark": UIColor("#2D2E3F"),
				"StrokeToastNeutralDark": UIColor("#3C3D50"),
				"TintGeneral": UIColor("#000000", alpha: 0.75),
				"TintContext": UIColor("#000000", alpha: 0.2),
				
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
				"gradPanelAttributes-1": UIColor("#181826", alpha: 0.5),
				"gradPanelAttributes-2": UIColor("#181826", alpha: 0.2),
				"gradSliderCircle-1": UIColor("#FFFFFF"),
				"gradSliderCircle-2": UIColor("#9b9cb4"),
				"gradStrokeSlider-1": UIColor("#3F427E"),
				"gradStrokeSlider-2": UIColor("#464A8B"),
				"gradExpBorderTop-1": UIColor("#343AA8"),
				"gradExpBorderTop-2": UIColor("#272D89"),
				"gradExpBorderMiddle-1": UIColor("#272D89"),
				"gradExpBorderMiddle-2": UIColor("#272D89"),
				"gradExpBorderBottom-1": UIColor("#272D89"),
				"gradExpBorderBottom-2": UIColor("#161A5F"),
				"gradGraphToken-1": UIColor("#555CCA", alpha: 0.48),
				"gradGraphToken-2": UIColor("#555CCA", alpha: 0),
				"gradUnconfirmed-1": UIColor("#272D89", alpha: 0.22),
				"gradUnconfirmed-2": UIColor("#161A5F", alpha: 0.15),
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

