//
//  StorageService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation

public class StorageService {
	
	private static let biometricEnabledKey = "app.kukai.wallet.biometeric-enabled"
	private static let passwordEnabledKey = "app.kukai.wallet.password-enabled"
	private static let passwordKey = "app.kukai.wallet.password"
	private static let completedOnboardinKey = "app.kukai.wallet.completed-onboarding"
	
	public struct settingsKeys {
		public static let collectiblesGroupModeEnabled = "app.kukai.collectibles.group-mode"
	}
	
	public static func setBiometricEnabled(_ enabled: Bool) {
		KeychainWrapper.standard.set(enabled, forKey: StorageService.biometricEnabledKey)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return KeychainWrapper.standard.bool(forKey: StorageService.biometricEnabledKey) ?? false
	}
	
	public static func setPasswordEnabled(_ enabled: Bool) {
		KeychainWrapper.standard.set(enabled, forKey: StorageService.passwordEnabledKey)
	}
	
	public static func isPasswordEnabled() -> Bool {
		return KeychainWrapper.standard.bool(forKey: StorageService.passwordEnabledKey) ?? false
	}
	
	public static func setPassword(_ password: String) {
		KeychainWrapper.standard.set(password, forKey: StorageService.passwordKey)
	}
	
	public static func validatePassword(_ password: String) -> Bool? {
		if let secret = KeychainWrapper.standard.string(forKey: StorageService.passwordKey) {
			return password == secret
		}
		
		return nil
	}
	
	public static func setCompletedOnboarding(_ complete: Bool) {
		KeychainWrapper.standard.set(complete, forKey: StorageService.completedOnboardinKey)
	}
	
	public static func didCompleteOnboarding() -> Bool {
		return KeychainWrapper.standard.bool(forKey: StorageService.completedOnboardinKey) ?? false
	}
}
