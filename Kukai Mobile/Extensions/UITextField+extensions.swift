//
//  UITextField+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2021.
//

import UIKit

extension UITextField {
	
	func addDoneToolbar(onDone: (target: Any, action: Selector)? = nil) {
		let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))

		let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
		toolbar.barStyle = .default
		
		toolbar.items = [
			UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
			UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
		]
		toolbar.sizeToFit()

		self.inputAccessoryView = toolbar
	}
	
	@objc func doneButtonTapped() {
		self.resignFirstResponder()
	}
}
