//
//  StorageService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation

public class StorageService {
	
	private static let secureLoginInfo = "app.kukai.wallet.login"
	private static let onboardingComplete = "app.kukai.onboarding.complete"
	
	@objc(_TtCC12Kukai_Mobile14StorageServiceP33_43FB357E44C0FD6E6F611B5FA483FE9D9LoginInfo)
	private class LoginInfo: NSObject, NSCoding {
		var isBiometricEnabled: Bool
		var isPasswordEnabled: Bool
		var password: String
		
		init(isBiometricEnabled: Bool, isPasswordEnabled: Bool, password: String) {
			self.isBiometricEnabled = isBiometricEnabled
			self.isPasswordEnabled = isPasswordEnabled
			self.password = password
		}
		
		required convenience init?(coder: NSCoder) {
			let bio = coder.decodeBool(forKey: "isBiometricEnabled")
			let passSet = coder.decodeBool(forKey: "isPasswordEnabled")
			
			guard let password = coder.decodeObject(forKey: "password") as? String else {
				return nil
			}
			
			self.init(isBiometricEnabled: bio, isPasswordEnabled: passSet, password: password)
		}
		
		func encode(with coder: NSCoder) {
			coder.encode(isBiometricEnabled, forKey: "isBiometricEnabled")
			coder.encode(isPasswordEnabled, forKey: "isPasswordEnabled")
			coder.encode(password, forKey: "password")
		}
	}
	
	
	
	public struct settingsKeys {
		public static let collectiblesGroupModeEnabled = "app.kukai.collectibles.group-mode"
	}
	
	
	
	// MARK: - Functions
	
	private static func getLoginInfo() -> LoginInfo? {
		return KeychainWrapper.standard.object(forKey: StorageService.secureLoginInfo, withAccessibility: .whenUnlockedThisDeviceOnly) as? LoginInfo
	}
	
	private static func setLoginInfo(_ info: LoginInfo) {
		KeychainWrapper.standard.set(info, forKey: StorageService.secureLoginInfo, withAccessibility: .whenUnlockedThisDeviceOnly)
	}
	
	public static func deleteKeychainItems() {
		KeychainWrapper.standard.removeObject(forKey: StorageService.secureLoginInfo, withAccessibility: .whenUnlockedThisDeviceOnly)
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
