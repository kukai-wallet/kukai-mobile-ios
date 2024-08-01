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
		static let isUserPresenceAvailable = "app.kukai.login.presence.available"
		static let wasBiometricAccesisbleDuringOnboarding = "app.kukai.login.biometrics.accessible.onboarding"
		
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
	
	public enum PasscodeStoreResult {
		case success
		case failure
		case biometricSetupError
	}
	
	
	
	// MARK: - Cleanup
	
	public static func deleteKeychainItems() {
		if !StorageService.isPrewarming() {
			KeychainSwift().clear()
		}
	}
	
	/// Prewarming occurs on iOS devices from iOS 15 onwards. When full disk protection is turned on keychain/user defaults/files etc are inaccessible and will return nil/false/error
	/// This causes a lot of issues with boolean checks for userDefault items that control keychain clean up, which can be triggered during prewarming, despite apples docs saying it can't. This has been proven to be incorrect
	/// Since this app uses disk protection, we can detect prewarming by setting a bool in userdefaults and then checking its value. Only situation it can be false is if the app is prewarming
	/// This can then be used as a fallback safety check. E.g. inside the keychain clear function, do not clear under prewarming at all
	public static func isPrewarming() -> Bool {
		let specialKey = "PREWARMING_CHECK" // not a constant as can NOT be used elsewhere
		
		UserDefaults.standard.set(true, forKey: specialKey)
		return UserDefaults.standard.bool(forKey: specialKey) == false
	}
	
	/// Allowing recovery from a strange prewarming issue where the keychain gets deleted during a warming, but the rest of the data remains, causing a weird edge case where the app has wallets but no PIN
	/// Because checking for the existence of the passcode may trigger FaceID/TouchID, we first need to check if its set. If its false or nil, check if passcode is nil. If biometric is set to ture, then keychain hasn't been deleted
	public static func isPasscodeNil() -> Bool {
		let isBiometricEnabled = (KeychainSwift().getBool(StorageService.KeychainKeys.isBiometricEnabled) == true)
		if isBiometricEnabled == false && KeychainSwift().get(StorageService.KeychainKeys.passcode) == nil {
			return true
		}
		
		return false
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
	public static func validateTempPasscodeAndCommit(_ passcode: String) -> PasscodeStoreResult {
		guard let hash = KeychainSwift().get(StorageService.KeychainKeys.tempPasscode) else {
			return .failure
		}
		
		if Sodium.shared.pwHash.strVerify(hash: hash, passwd: passcode.bytes) {
			return recordPasscode(passcode)
		}
		
		return .failure
	}
	
	public static func wasBiometricsAccessibleDuringOnboarding() -> Bool {
		return KeychainSwift().getBool(StorageService.KeychainKeys.wasBiometricAccesisbleDuringOnboarding) ?? false
	}
	
	/// Delete previous record (if present) and create a new one with usePresence set
	private static func recordPasscode(_ passcode: String) -> PasscodeStoreResult {
		guard let hash = Sodium.shared.pwHash.str(passwd: passcode.bytes, opsLimit: Sodium.shared.pwHash.OpsLimitInteractive, memLimit: Sodium.shared.pwHash.MemLimitInteractive) else {
			return .failure
		}
		
		// There is a strange iOS issue with users who have damaged the hardware connected to their biometrics.
		// iOS will say the phone supports biometrics, but app is unable to make use of it, returning an error.
		// So to allow people to install the app, and not implement a security hole. We will check if its possible to use userPresence with a dummy keychain value
		// If this fails during onboard, all biometric logic will be turned off
		//
		// Recording the passcode only once with biometic flag, means when biometric enabled, users are unable to enter the passcode on its own (i.e. tapping cancel to biometric)
		// Because retrieving the passcode to do the verification requires succesful biometrics
		// Instead it needs to be stored twice, once where it can be accessed without biometrics and one with to enable both cases
		let res1 = isUserPresenceAvailable() ? recordPasscodeHash(hash, withUserPresence: true) : true
		let res2 = recordPasscodeHash(hash, withUserPresence: false)
		
		if res1 == false {
			return .biometricSetupError
			
		} else if res1 && res2 {
			return .success
			
		} else {
			return .failure
		}
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
	
	private static func isUserPresenceAvailable() -> Bool {
		guard let accessControl = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryAny, nil),
			  let hashData = "available".data(using: .utf8) else {
			return false
		}
		
		KeychainSwift().delete(StorageService.KeychainKeys.isUserPresenceAvailable)
		let query = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: StorageService.KeychainKeys.isUserPresenceAvailable,
			kSecValueData: hashData,
			kSecAttrAccessControl: accessControl,
			kSecReturnData: true
		] as [CFString: Any] as CFDictionary
		
		var result: AnyObject?
		let status = SecItemAdd(query, &result)
		
		// Record what happened for later retreival without triggering biometrics to check
		if status != 0 {
			KeychainSwift().set(false, forKey: StorageService.KeychainKeys.wasBiometricAccesisbleDuringOnboarding, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
			return false
		} else {
			KeychainSwift().set(true, forKey: StorageService.KeychainKeys.wasBiometricAccesisbleDuringOnboarding, withAccess: .accessibleWhenUnlockedThisDeviceOnly)
			return true
		}
	}
	
	private static func getPasscode(withUserPresence: Bool, completion: @escaping ((String?) -> Void)) {
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
