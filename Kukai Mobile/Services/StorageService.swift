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
		static let tempPasscode = "app.kukai.login.passcode.temp"
		static let passcode = "app.kukai.login.passcode"
		static let passcodeBiometric = "app.kukai.login.passcode.biometric"
		static let isBiometricEnabled = "app.kukai.login.biometric.enabled"
		
		static let loginWrongGuessCount = "app.kukai.login.count"
		static let loginWrongGuessDelay = "app.kukai.login.delay"
		
		static let lastLogin = "app.kukai.login.last"
	}
	
	private struct UserDefaultKeys {
		static let onboardingComplete = "app.kukai.onboarding.complete"
		public static let hasShownJailbreakWarning = "app.kukai.jailbreak.warning"
	}
	
	public struct settingsKeys {
		public static let collectiblesGroupModeEnabled = "app.kukai.collectibles.group-mode"
	}
	
	
	
	// MARK: - Cleanup
	
	public static func deleteKeychainItems() {
		KeychainSwift().clear()
	}
	
	
	
	// MARK: - Keychain
	
	/// Temporarily store newly entered passcode until creation flow complete
	public static func recordTempPasscode(_ passcode: String) -> Bool {
		guard let hash = Sodium.shared.pwHash.str(passwd: passcode.bytes, opsLimit: Sodium.shared.pwHash.OpsLimitInteractive, memLimit: Sodium.shared.pwHash.MemLimitInteractive) else {
			return false
		}
		
		return KeychainSwift().set(hash, forKey: StorageService.KeychainKeys.tempPasscode, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	/// Compare temporary passcode with user supplied passcode. If valid, commit passcode to real storage (overwritting if necessary)
	public static func validateTempPasscodeAndCommit(_ passcode: String) -> Bool {
		guard let hash = KeychainSwift().get(StorageService.KeychainKeys.tempPasscode) else {
			return false
		}
		
		if Sodium.shared.pwHash.strVerify(hash: hash, passwd: passcode.bytes) {
			return recordPasscode(passcode)
		}
		
		return false
	}
	
	/// Delete previous record (if present) and create a new one with usePresence set
	private static func recordPasscode(_ passcode: String) -> Bool {
		guard let hash = Sodium.shared.pwHash.str(passwd: passcode.bytes, opsLimit: Sodium.shared.pwHash.OpsLimitInteractive, memLimit: Sodium.shared.pwHash.MemLimitInteractive) else {
			return false
		}
		
		// Recording the passcode only once with biometic flag, means when biometric enabled, users are unable to enter the passcode on its own (i.e. tapping cancel to biometric)
		// Because retrieving the passcode to do the verification requires succesful biometrics
		// Instead it needs to be stored twice, once where it can be accessed without biometrics and one with to enable both cases
		return recordPasscodeHash(hash, withUserPresence: true) && recordPasscodeHash(hash, withUserPresence: false)
	}
	
	private static func recordPasscodeHash(_ hash: String, withUserPresence: Bool) -> Bool {
		if !withUserPresence {
			KeychainSwift().delete(StorageService.KeychainKeys.passcode)
			return KeychainSwift().set(hash, forKey: StorageService.KeychainKeys.passcode, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
		}
		
		// KeychainSwift doesn't support .userPresence setting, handle this one case custom until a replacement library is found
		guard let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryAny, nil),
			  let hashData = hash.data(using: .utf8) else {
			return false
		}
		
		KeychainSwift().delete(StorageService.KeychainKeys.passcodeBiometric)
		let query = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: StorageService.KeychainKeys.passcodeBiometric,
			kSecValueData: hashData,
			kSecAttrAccessControl: accessControl,
			kSecReturnData: true
		] as [CFString: Any] as CFDictionary
		
		var result: AnyObject?
		let status = SecItemAdd(query, &result)
		
		return status == 0
	}
	
	private static func getPasscode(withUserPresence: Bool, completion: @escaping ((String?) -> Void)){
		if withUserPresence {
			
			/// SecItemCopyMatching blocks the calling thread, must be moved to background thread
			DispatchQueue.global(qos: .background).async {
				let searchQuery = [
					kSecClass: kSecClassGenericPassword,
					kSecAttrAccount: StorageService.KeychainKeys.passcodeBiometric,
					kSecMatchLimit: kSecMatchLimitOne,
					kSecReturnData: true,
				] as [CFString : Any] as CFDictionary
				
				
				var item: AnyObject?
				let status = SecItemCopyMatching(searchQuery, &item)
				
				guard status == 0, let data = (item as? Data) else {
					DispatchQueue.main.async { completion(nil) }
					return
				}
				
				DispatchQueue.main.async { completion(String(data: data, encoding: .utf8)) }
			}
			
		} else {
			completion(KeychainSwift().get(StorageService.KeychainKeys.passcode))
		}
	}
	
	public static func validatePasscode(_ passcode: String, withUserPresence: Bool, completion: @escaping ((Bool) -> Void)) {
		getPasscode(withUserPresence: withUserPresence) { hash in
			guard let h = hash else {
				completion(false)
				return
			}
			
			completion( Sodium.shared.pwHash.strVerify(hash: h, passwd: passcode.bytes) )
		}
	}
	
	public static func setBiometricEnabled(_ enabled: Bool) -> Bool {
		return KeychainSwift().set(enabled, forKey: StorageService.KeychainKeys.isBiometricEnabled, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return KeychainSwift().getBool(StorageService.KeychainKeys.isBiometricEnabled) ?? false
	}
	
	public static func authWithBiometric(completion: @escaping ((Bool) -> Void)) {
		if isBiometricEnabled() {
			getPasscode(withUserPresence: true) { rawPasscodeWithUserPresence in
				completion(rawPasscodeWithUserPresence != nil)
			}
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
		KeychainSwift().set(count.description, forKey: StorageService.KeychainKeys.loginWrongGuessCount, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	public static func getLoginDelay() -> Int? {
		guard let str = KeychainSwift().get(StorageService.KeychainKeys.loginWrongGuessDelay), let asInt = Int(str)  else {
			return nil
		}
		
		return asInt
	}
	
	public static func setLoginDelay(_ count: Int) {
		KeychainSwift().set(count.description, forKey: StorageService.KeychainKeys.loginWrongGuessDelay, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	
	
	
	// MARK: - Last login checks
	
	/// Check if we are able to skip the login (last login was less than X seconds ago). Also double check that no login delay is in place as a safety check
	public static func canSkipLogin() -> Bool {
		if (getLoginDelay() ?? 0) > 0 {
			return false
		}
		
		let lastTimestamp = getLastLogin()
		let currentTimestamp = Date().timeIntervalSince1970
		
		return (currentTimestamp - lastTimestamp) < 60
	}
	
	public static func setLastLogin() {
		let timestamp = Date().timeIntervalSince1970
		KeychainSwift().set(timestamp.description, forKey: StorageService.KeychainKeys.lastLogin, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
	}
	
	public static func getLastLogin() -> TimeInterval {
		guard let string = KeychainSwift().get(StorageService.KeychainKeys.lastLogin) else {
			return 0
		}
		
		return Double(string) ?? 0
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
	
	public static func recordJailbreakWarning() {
		UserDefaults.standard.set(true, forKey: StorageService.UserDefaultKeys.hasShownJailbreakWarning)
	}
	
	public static func needsToShowJailbreakWanring() -> Bool {
		if UserDefaults.standard.bool(forKey: StorageService.UserDefaultKeys.hasShownJailbreakWarning) == false, canEditSandboxFilesForJailbreakDetection() {
			return true
		}
		
		return false
	}
	
	static func canEditSandboxFilesForJailbreakDetection() -> Bool {
		let jailBreakTestText = "Test for Jailbreak"
		do {
			try jailBreakTestText.write(toFile: "/private/jailbreakTestText.txt", atomically: true, encoding: .utf8)
			return true
		} catch {
			return false
		}
	}
}
