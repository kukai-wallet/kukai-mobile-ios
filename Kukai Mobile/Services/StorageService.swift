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
	
	
	// MARK: - Types
	
	private struct KeychainKeys {
		static let passcode = "app.kukai.login.passcode"
		static let isBiometricEnabled = "app.kukai.login.biometric.enabled"
		
		static let loginWrongGuessCount = "app.kukai.login.count"
		static let loginWrongGuessDelay = "app.kukai.login.delay"
	}
	
	private struct UserDefaultKeys {
		static let onboardingComplete = "app.kukai.onboarding.complete"
	}
	
	public struct settingsKeys {
		public static let collectiblesGroupModeEnabled = "app.kukai.collectibles.group-mode"
	}
	
	
	
	// MARK: - Cleanup
	
	public static func deleteKeychainItems() {
		KeychainSwift().clear()
	}
	
	
	
	// MARK: - Keychain
	
	public static func setPasscode(_ passcode: String, withUserPresence: Bool = false) -> Bool {
		StorageService.recordPasscode(passcode, withUserPresence: withUserPresence)
	}
	
	/// Delete previous record (if present) and create a new one with usePresence set
	private static func recordPasscode(_ passcode: String, withUserPresence: Bool) -> Bool {
		guard let hash = Sodium.shared.pwHash.str(passwd: passcode.bytes, opsLimit: Sodium.shared.pwHash.OpsLimitInteractive, memLimit: Sodium.shared.pwHash.MemLimitInteractive) else {
			return false
		}
		
		return recordPasscodeHash(hash, withUserPresence: withUserPresence)
	}
	
	private static func recordPasscodeHash(_ hash: String, withUserPresence: Bool) -> Bool {
		KeychainSwift().delete(StorageService.KeychainKeys.passcode)
		
		if !withUserPresence {
			return KeychainSwift().set(hash, forKey: StorageService.KeychainKeys.passcode, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
		}
		
		// KeychainSwift doesn't support .userPresence setting, handle this one case custom until a replacement library is found
		guard let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryAny, nil),
			  let hashData = hash.data(using: .utf8) else {
			return false
		}
		
		let query = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: StorageService.KeychainKeys.passcode,
			kSecValueData: hashData,
			kSecAttrAccessControl: accessControl,
			kSecReturnData: true
		] as [CFString: Any] as CFDictionary
		
		var result: AnyObject?
		let status = SecItemAdd(query, &result)
		
		return status == 0
	}
	
	private static func getPasscode() -> String? {
		if isBiometricEnabled() {
			let searchQuery = [
				kSecClass: kSecClassGenericPassword,
				kSecAttrAccount: StorageService.KeychainKeys.passcode,
				kSecMatchLimit: kSecMatchLimitOne,
				kSecReturnData: true,
			] as [CFString : Any] as CFDictionary
			
			var item: AnyObject?
			let status = SecItemCopyMatching(searchQuery, &item)
			
			guard status == 0, let data = (item as? Data) else {
				return nil
			}
			
			return String(data: data, encoding: .utf8)
			
		} else {
			return KeychainSwift().get(StorageService.KeychainKeys.passcode)
		}
	}
	
	public static func validatePasscode(_ passcode: String) -> Bool {
		guard let hash = getPasscode() else {
			return false
		}
		
		return Sodium.shared.pwHash.strVerify(hash: hash, passwd: passcode.bytes)
	}
	
	public static func setBiometricEnabled(_ enabled: Bool) -> Bool {
		guard let rawPasscode = getPasscode() else {
			return false
		}
		
		KeychainSwift().set(enabled, forKey: StorageService.KeychainKeys.isBiometricEnabled)
		
		return recordPasscodeHash(rawPasscode, withUserPresence: enabled)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return KeychainSwift().getBool(StorageService.KeychainKeys.isBiometricEnabled) ?? false
	}
	
	public static func authWithBiometric(completion: @escaping ((Bool) -> Void)) {
		if isBiometricEnabled() {
			let rawPasscodeWithUserPresence = getPasscode()
			completion(rawPasscodeWithUserPresence != nil)
		} else {
			completion(false)
		}
	}
	
	
	
	// MARK: - Login delays
	
	public static func getLoginCount() -> Int? {
		guard let str = KeychainSwift().get(StorageService.KeychainKeys.loginWrongGuessCount), let asInt = Int(str)  else {
			return nil
		}
		
		return asInt
	}
	
	public static func setLoginCount(_ count: Int) {
		KeychainSwift().set(count.description, forKey: StorageService.KeychainKeys.loginWrongGuessCount)
	}
	
	public static func getLoginDelay() -> Int? {
		guard let str = KeychainSwift().get(StorageService.KeychainKeys.loginWrongGuessDelay), let asInt = Int(str)  else {
			return nil
		}
		
		return asInt
	}
	
	public static func setLoginDelay(_ count: Int) {
		KeychainSwift().set(count.description, forKey: StorageService.KeychainKeys.loginWrongGuessDelay)
	}
	
	
	
	// MARK: Onboarding
	
	public static func hasUserDefaultKeyBeenSet(key: String) -> Bool {
		return UserDefaults.standard.object(forKey: key) != nil
	}
	
	// Store these in userdefaults to act as a gatekeeper to keychain data
	// Keychain data is not removed on uninstall, but everything else will be. We don't want that lingering around
	// so check everytime app launches from closed, is this false, if so, blitz keychain data
	public static func setCompletedOnboarding(_ complete: Bool) {
		UserDefaults.standard.set(complete, forKey: StorageService.UserDefaultKeys.onboardingComplete)
	}
	
	public static func didCompleteOnboarding() -> Bool {
		return UserDefaults.standard.bool(forKey: StorageService.UserDefaultKeys.onboardingComplete)
	}
}
