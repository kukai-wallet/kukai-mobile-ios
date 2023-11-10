//
//  FaceIdViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit
import KukaiCoreSwift
import LocalAuthentication

class FaceIdViewController: UIViewController {
	
	@IBOutlet weak var biometricImage: UIImageView!
	@IBOutlet weak var biometricLabel: UILabel!
	@IBOutlet weak var toggle: UISwitch!
	@IBOutlet weak var nextButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		nextButton.customButtonType = .primary
		
		if CurrentDevice.biometricTypeSupported() == .touchID {
			biometricImage.image = UIImage(systemName: "touchid")
			biometricLabel.text = "Use Touch ID"
		}
		
		if isModal {
			nextButton.isHidden = true
			toggle.isOn = StorageService.isBiometricEnabled()
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
	}
	
	@IBAction func nextTapped(_ sender: Any) {
		if toggle.isOn {
			FaceIdViewController.biometric { errorMessage in
				if let err = errorMessage {
					self.windowError(withTitle: "error".localized(), description: err)
				} else {
					self.navigateNext()
				}
			}
			
		} else {
			let _ = StorageService.setBiometricEnabled(false)
			StorageService.setCompletedOnboarding(true)
			self.navigateNext()
		}
	}
	
	func navigateNext() {
		let importVc = self.navigationController?.viewControllers.filter({ $0 is ImportWalletViewController }).first
		let socialVc = self.navigationController?.viewControllers.filter({ $0 is CreateWithSocialViewController }).first
		let watchVc = self.navigationController?.viewControllers.filter({ $0 is WatchWalletViewController }).first
		
		if importVc != nil || socialVc != nil || watchVc != nil {
			self.performSegue(withIdentifier: "home", sender: self)
		} else {
			self.performSegue(withIdentifier: "next", sender: nil)
		}
	}
	
	public static func handleBiometricChangeTo(isOn: Bool, completion: @escaping ((String?) -> Void)) {
		if isOn {
			biometric(completion: completion)
		} else if StorageService.setBiometricEnabled(false) {
			DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5) {
				completion(nil)
			}
		} else {
			completion("Unable to complete request")
		}
	}
	
	private static func biometric(completion: @escaping ((String?) -> Void)) {
		let context = LAContext()
		var error: NSError?
		
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			let reason = "To allow access to your app"
			
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
				DispatchQueue.main.async {
					if success, StorageService.setBiometricEnabled(true) {
						completion(nil)
						
					} else if success == false && (authenticationError?.code == -6 && (authenticationError?.userInfo["NSDebugDescription"] as? String) == "User has denied the use of biometry for this app."), StorageService.setBiometricEnabled(false) {
						completion(nil)
						
					} else {
						completion("Error occured requesting permission: \(String(describing: authenticationError))")
					}
				}
			}
		} else {
			completion("No biometrics available on this device")
		}
	}
}
