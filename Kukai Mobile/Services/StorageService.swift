//
//  StorageService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation
import KeychainSwift

public class StorageService {
	
	private static let secureLoginInfo = "app.kukai.wallet.login"
	private static let onboardingComplete = "app.kukai.onboarding.complete"
	
	private class LoginInfo: Codable {
		var isBiometricEnabled: Bool
		var isPasswordEnabled: Bool
		var password: String
		
		init(isBiometricEnabled: Bool, isPasswordEnabled: Bool, password: String) {
			self.isBiometricEnabled = isBiometricEnabled
			self.isPasswordEnabled = isPasswordEnabled
			self.password = password
		}
	}
	
	
	
	public struct settingsKeys {
		public static let collectiblesGroupModeEnabled = "app.kukai.collectibles.group-mode"
	}
	
	
	
	// MARK: - Functions
	
	private static func getLoginInfo() -> LoginInfo? {
		guard let data = KeychainSwift().getData(StorageService.secureLoginInfo), let obj = try? JSONDecoder().decode(LoginInfo.self, from: data) else {
			return nil
		}
		
		return obj
	}
	
	private static func setLoginInfo(_ info: LoginInfo) {
		guard let data = try? JSONEncoder().encode(info) else {
			return
		}
		
		KeychainSwift().set(data, forKey: StorageService.secureLoginInfo, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	public static func deleteKeychainItems() {
		
		KeychainSwift().delete(StorageService.secureLoginInfo)
	}
	
	public static func setBiometricEnabled(_ enabled: Bool) {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, password: "")
		currentInfo.isBiometricEnabled = enabled
		setLoginInfo(currentInfo)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return getLoginInfo()?.isBiometricEnabled ?? false
	}
	
	public static func setPasswordEnabled(_ enabled: Bool) {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, password: "")
		currentInfo.isPasswordEnabled = enabled
		setLoginInfo(currentInfo)
	}
	
	public static func isPasswordEnabled() -> Bool {
		return getLoginInfo()?.isPasswordEnabled ?? false
	}
	
	public static func setPassword(_ password: String) {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, password: "")
		currentInfo.password = password
		setLoginInfo(currentInfo)
	}
	
	public static func validatePassword(_ password: String) -> Bool? {
		if let secret = getLoginInfo()?.password {
			return password == secret
		}
		
		return nil
	}
	
	public static func hasUserDefaultKeyBeenSet(key: String) -> Bool {
		return UserDefaults.standard.object(forKey: key) != nil
	}
	
	
	
	// Store these in userdefaults to act as a gatekeeper to keychain data
	// Keychain data is not removed on uninstall, but everything else will be. We don't want that lingering around
	// so check everytime app launches from closed, is this false, if so, blitz keychain data
	public static func setCompletedOnboarding(_ complete: Bool) {
		UserDefaults.standard.set(complete, forKey: StorageService.onboardingComplete)
	}
	
	public static func didCompleteOnboarding() -> Bool {
		return UserDefaults.standard.bool(forKey: StorageService.onboardingComplete)
	}
	
	public static func runCleanupChecks() {
		if didCompleteOnboarding() == false {
			deleteKeychainItems()
		}
	}
}
