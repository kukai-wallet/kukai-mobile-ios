//
//  CustomNavigationController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/05/2024.
//

import UIKit

class CustomNavigationController: UINavigationController {
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		updateNavBar()
	}
	
	func updateNavBar() {
		for view in self.navigationBar.subviews {
			
			let string = "\(view.classForCoder)"
			if string.contains("ContentView") {
				
				// Adjust left and right constraints of the content view
				for constraint in view.constraints {
					if constraint.firstAttribute == .leading || constraint.secondAttribute == .leading {
						
						if constraint.constant > 12 {
							constraint.constant = 16
						}
						
					} else if constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing {
						
						if constraint.constant < -12 {
							constraint.constant = -16
						}
					}
				}
				
				// Adjust constraints between items in stack view
				for subview in view.subviews {
					
					if subview is UIStackView {
						for constraint in subview.constraints {
							if constraint.firstAttribute == .width || constraint.secondAttribute == .width {
								constraint.constant = 0
							}
						}
					}
				}
			}
		}
	}
}
