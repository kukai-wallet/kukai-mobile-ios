//
//  SideMenuImportViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit

class SideMenuImportViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.backgroundColor = .clear
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Fade in background and slide in content view
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.backgroundColor = UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 0.5)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		self.navigationController?.setNavigationBarHidden(false, animated: false)
	}
}
