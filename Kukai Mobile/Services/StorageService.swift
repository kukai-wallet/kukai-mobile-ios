//
//  StorageService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation
import KeychainSwift
import Sodium

public class StorageService {
	
	private static let secureLoginInfo = "app.kukai.wallet.login"
	private static let onboardingComplete = "app.kukai.onboarding.complete"
	private static let loginWrongGuessCount = "app.kukai.login.count"
	private static let loginWrongGuessDelay = "app.kukai.login.delay"
	
	private class LoginInfo: Codable {
		var isBiometricEnabled: Bool
		var isPasswordEnabled: Bool
		var passcode: String
		
		init(isBiometricEnabled: Bool, isPasswordEnabled: Bool, passcode: String) {
			self.isBiometricEnabled = isBiometricEnabled
			self.isPasswordEnabled = isPasswordEnabled
			self.passcode = passcode
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
	
	private static func loginInfoExists() -> Bool {
		return (getLoginInfo() != nil)
	}
	
	public static func deleteKeychainItems() {
		KeychainSwift().clear()
	}
	
	public static func setBiometricEnabled(_ enabled: Bool) {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, passcode: "")
		currentInfo.isBiometricEnabled = enabled
		setLoginInfo(currentInfo)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return getLoginInfo()?.isBiometricEnabled ?? false
	}
	
	public static func setPasscodeEnabled(_ enabled: Bool) {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, passcode: "")
		currentInfo.isPasswordEnabled = enabled
		setLoginInfo(currentInfo)
	}
	
	public static func isPasscodeEnabled() -> Bool {
		return getLoginInfo()?.isPasswordEnabled ?? false
	}
	
	public static func setPasscode(_ passcode: String) -> Bool {
		let currentInfo = getLoginInfo() ?? LoginInfo(isBiometricEnabled: false, isPasswordEnabled: false, passcode: "")
		guard let hash = Sodium.shared.pwHash.str(passwd: passcode.bytes, opsLimit: Sodium.shared.pwHash.OpsLimitInteractive, memLimit: Sodium.shared.pwHash.MemLimitInteractive) else {
			return false
		}
		
		currentInfo.passcode = hash
		setLoginInfo(currentInfo)
		
		return true
	}
	
	public static func validatePasscode(_ passcode: String) -> Bool? {
		if let secret = getLoginInfo()?.passcode {
			return Sodium.shared.pwHash.strVerify(hash: secret, passwd: passcode.bytes)
		}
		
		return nil
	}
	
	public static func getLoginCount() -> Int? {
		guard let str = KeychainSwift().get(StorageService.loginWrongGuessCount), let asInt = Int(str)  else {
			return nil
		}
		
		return asInt
	}
	
	public static func setLoginCount(_ count: Int) {
		KeychainSwift().set(count.description, forKey: StorageService.loginWrongGuessCount)
	}
	
	public static func getLoginDelay() -> Int? {
		guard let str = KeychainSwift().get(StorageService.loginWrongGuessDelay), let asInt = Int(str)  else {
			return nil
		}
		
		return asInt
	}
	
	public static func setLoginDelay(_ count: Int) {
		KeychainSwift().set(count.description, forKey: StorageService.loginWrongGuessDelay)
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
}
