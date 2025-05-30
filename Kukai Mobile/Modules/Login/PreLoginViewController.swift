//
//  PreLoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit
import Combine

class PreLoginViewController: UIViewController {
	
	private var bag = [AnyCancellable]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationController?.overrideUserInterfaceStyle = ThemeManager.shared.currentInterfaceStyle()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		// If `canSkipLogin()` is true, we want to run this code before the login screen has a chance present anything, to prevent any flashes of the keyboard or biometric UI etc
		// However `viewDidAppear()` will get triggered when the app is moving from foreground -> background mode, so that can't be relied on to run that logic as it would remain true if the user closed the app before the timer
		// So we need to run a "firstLoad" check inside viewDidAppear to allow login to display from a clod open
		// Then we can use this to run checks for `canSkipLogin` every other time app moves from background -> foreground as early as possible
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			if StorageService.canSkipLogin() {
				LoginViewController.reconnectAndDismiss()
			} else {
				self?.performSegue(withIdentifier: "login", sender: self)
			}
		}.store(in: &bag)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
			self.performSegue(withIdentifier: "login", sender: self)
			return
		}
		
		if sceneDelegate.firstLoad {
			self.performSegue(withIdentifier: "login", sender: self)
		}
	}
}
