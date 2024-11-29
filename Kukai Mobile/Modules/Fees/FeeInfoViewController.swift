//
//  FeeInfoViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 02/02/2023.
//

import UIKit

class FeeInfoViewController: UIViewController {
	
	@IBInspectable var addGradient: Bool = true
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = .clear
		
		if addGradient {
			GradientView.add(toView: self.view, withType: .fullScreenBackground)
		}
    }
}
