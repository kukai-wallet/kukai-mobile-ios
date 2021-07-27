//
//  PreLoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit

class PreLoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		print("viewWillAppear")
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		print("viewDidAppear")
		
		self.performSegue(withIdentifier: "login", sender: self)
	}
}
