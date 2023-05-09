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
	@IBOutlet weak var createPasswordWarning: UILabel!
	@IBOutlet weak var nextButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		nextButton.customButtonType = .primary
		createPasswordWarning.isHidden = true
		
		if CurrentDevice.biometricType() == .touch {
			biometricImage.image = UIImage(systemName: "touchid")
			biometricLabel.text = "Use Touch ID"
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
	}
	
	@IBAction func toggleChanged(_ sender: Any) {
		createPasswordWarning.isHidden = toggle.isOn
	}
	
	@IBAction func nextTapped(_ sender: Any) {
		if toggle.isOn {
			biometricAndHome()
			
		} else {
			self.performSegue(withIdentifier: "password", sender: self)
		}
	}
	
	func biometricAndHome() {
		let context = LAContext()
		var error: NSError?
		
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			let reason = "To allow access to your app"
			
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
				[weak self] success, authenticationError in
				
				DispatchQueue.main.async { [weak self] in
					if success {
						SecureLoginService.setBiometricEnabled(true)
						SecureLoginService.setCompletedOnboarding(true)
						self?.performSegue(withIdentifier: "home", sender: nil)
						
					} else {
						self?.alert(errorWithMessage: "Error occured requesting permission: \(String(describing: authenticationError))")
					}
				}
			}
		} else {
			self.alert(errorWithMessage: "No biometrics available on this device")
		}
	}
}
