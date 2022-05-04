//
//  SideMenuImportViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2022.
//

import UIKit

class SideMenuImportViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		(self.presentingViewController as? SideMenuViewController)?.refeshWallets()
	}
}
