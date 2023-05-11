//
//  LoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit
import LocalAuthentication
import OSLog

class LoginViewController: UIViewController {
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// When integrate pin / face id, move this call to after successful
		reestablishConnectionsAfterLogin()
		
		if DependencyManager.shared.walletList.count() > 0 {
			validateBiometric()
		} else {
			self.returnToApp()
		}
	}
	
	private func validateBiometric() {
		let context = LAContext()
		var error: NSError?
		
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			let reason = "To allow access to app"
			
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
				[weak self] success, authenticationError in
				
				DispatchQueue.main.async {
					if success {
						self?.returnToApp()
						
					} else {
						self?.alert(errorWithMessage: "Unable to verify biometrics")
					}
				}
			}
		} else {
			self.alert(errorWithMessage: "No biometrics enabled, please enable and try again")
		}
	}
	
	private func returnToApp() {
		guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate else {
			os_log("Can't get scene delegate", log: .default, type: .debug)
			return
		}
		
		sceneDelegate.hidePrivacyProtectionWindow()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	
	private func reestablishConnectionsAfterLogin() {
		AccountViewModel.setupAccountActivityListener()
	}
}
