//
//  SecureLoginService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation

public class SecureLoginService {
	
	private static let biometricEnabledKey = "app.kukai.wallet.biometeric-enabled"
	private static let passwordEnabledKey = "app.kukai.wallet.password-enabled"
	private static let passwordKey = "app.kukai.wallet.password"
	private static let completedOnboardinKey = "app.kukai.wallet.completed-onboarding"
	
	public static func setBiometricEnabled(_ enabled: Bool) {
		KeychainWrapper.standard.set(enabled, forKey: SecureLoginService.biometricEnabledKey)
	}
	
	public static func isBiometricEnabled() -> Bool {
		return KeychainWrapper.standard.bool(forKey: SecureLoginService.biometricEnabledKey) ?? false
	}
	
	public static func setPasswordEnabled(_ enabled: Bool) {
		KeychainWrapper.standard.set(enabled, forKey: SecureLoginService.passwordEnabledKey)
	}
	
	public static func isPasswordEnabled() -> Bool {
		return KeychainWrapper.standard.bool(forKey: SecureLoginService.passwordEnabledKey) ?? false
	}
	
	public static func setPassword(_ password: String) {
		KeychainWrapper.standard.set(password, forKey: SecureLoginService.passwordKey)
	}
	
	public static func validatePassword(_ password: String) -> Bool? {
		if let secret = KeychainWrapper.standard.string(forKey: SecureLoginService.passwordKey) {
			return password == secret
		}
		
		return nil
	}
	
	public static func setCompletedOnboarding(_ complete: Bool) {
		KeychainWrapper.standard.set(complete, forKey: SecureLoginService.completedOnboardinKey)
	}
	
	public static func didCompleteOnboarding() -> Bool {
		return KeychainWrapper.standard.bool(forKey: SecureLoginService.completedOnboardinKey) ?? false
	}
}
