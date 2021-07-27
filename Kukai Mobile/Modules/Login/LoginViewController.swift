//
//  LoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit
import OSLog

class LoginViewController: UIViewController {

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		activityIndicator.startAnimating()
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
			guard let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate else {
				os_log("Can't get scene delegate", log: .default, type: .debug)
				return
			}
			
			sceneDelegate.hidePrivacyProtectionWindow()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		activityIndicator.stopAnimating()
	}
}
