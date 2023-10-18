//
//  RequiredUpdateViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/10/2023.
//

import UIKit

class RequiredUpdateViewController: UIViewController {
	
	@IBOutlet weak var updateButton: CustomisableButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		updateButton.customButtonType = .primary
    }
	
	@IBAction func updateButtonTapped(_ sender: Any) {
		
	}
}
