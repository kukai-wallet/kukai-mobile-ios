//
//  AppDelegate.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/07/2021.
//

import UIKit
import KukaiCoreSwift
import Sentry
import os.log

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	/**
	 DO NOT RUN ANY CODE HERE THAT TOUCHES USER DEFAULTS
	 
	 In iOS 15 apple added pre-warming, which allows the OS to partially load an app while its in a closed state. Despite ambiguity in apple docs, it DOES run willFinishLaunchingWithOptions & didFinishLaunchingWithOptions
	 With `NSFileProtectionComplete` turned on, values are unreadable inside xxxLaunchingWithOptions. This may result in booleans being returned as false simply because they can't be read, which can lead to broken cache logic
	 */
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		setupTheme()
		
		#if targetEnvironment(simulator)
			// If running on simulator, print documents directory to help with debugging
			if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
				Logger.app.info("Documents Directory: \(documentsPath)")
			}
		#endif
		
		// If not running on simulator, Setup Sentry, but with Anonymous events
		SentrySDK.start { options in
			options.dsn = "https://6078bc46bd5c46e1aa6a416c8043f9f4@o1056238.ingest.sentry.io/4505443257024512"
			options.enableWatchdogTerminationTracking = false
			options.enableSigtermReporting = false
			options.beforeSend = { (event) -> Event? in
				
				// Scrub any identifiable data to keep users anonymous
				event.context?["app"]?.removeValue(forKey: "device_app_hash")
				event.user = nil
				
				if event.level == .info, let message = event.message {
					// Sentry for some bizarre reason relies on stacktraces to group everything. So `captureMessage()`'s in the same file will all be grouped together based on function name
					// rather than based on message text. Overriding this behaviour globally (hopefully `.info` is only used for messages), as it makes no sense
					event.fingerprint = [message.formatted]
					
				} else if (event.exceptions?.first?.type == "App Hanging") {
					// Sentry tracks app hangs by stacktrace, which means in complex threaded code, the same underlying issue might get reported as hundreds of unique errors on the snetry dashboard
					// Instead overwrite that logic and group them all by app version, so that we can track whether or not version changes improve the situation overall
					let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
					let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
					let newTitle = "App Hanging - \(version) (\(build))"
					
					event.message = SentryMessage(formatted: newTitle)
					event.fingerprint = [newTitle]
				}
			
				return event
			}
		}
		
		
		// Setup any necessary settings, such as RAM limits
		MediaProxyService.setupImageLibrary()
		
		
		// process special arguments coming from XCUITest to do things like show keyboard and reset app data
		processXCUITestArguments()
		
		// Reset server URL list cache, incase its edited between versions
		if !StorageService.isPrewarming() {
			DependencyManager.shared.setNetworkTo(networkTo: DependencyManager.shared.currentNetworkType)
		}
		
		return true
	}
	
	func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
		return extensionPointIdentifier != .keyboard
	}
	
	func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
		MediaProxyService.imageCache(forType: .permanent).clearMemory()
		MediaProxyService.imageCache(forType: .temporary).clearMemory()
		MediaProxyService.imageCache(forType: .detail).clearMemory()
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
	
	
	
	
	
	// MARK: - Testing
	
	func processXCUITestArguments() {
		let environment = ProcessInfo.processInfo.environment
		
		if environment["XCUITEST-KEYBOARD"] == "true" {
			disconnectHardwareKeyboard()
		}
		
		if environment["XCUITEST-RESET"] == "true" {
			SideMenuResetViewController.resetAllDataAndCaches {
				print("XCUITEST-RESET = done")
			}
		}
		
		if environment["XCUITEST-STUB-XTZ-PRICE"] == "true" {
			DependencyManager.shared.stubXtzPrice = true
		}
	}
	
	func disconnectHardwareKeyboard() {
		#if targetEnvironment(simulator)
		// Disable hardware keyboards.
		let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
		UITextInputMode.activeInputModes
		// Filter `UIKeyboardInputMode`s.
			.filter({ $0.responds(to: setHardwareLayout) })
			.forEach { $0.perform(setHardwareLayout, with: nil) }
		#endif
	}
	
	func shouldLaunchGhostnet() -> Bool {
		let environment = ProcessInfo.processInfo.environment
		
		if environment["XCUITEST-GHOSTNET"] == "true" {
			return true
		}
		
		return false
	}
}
