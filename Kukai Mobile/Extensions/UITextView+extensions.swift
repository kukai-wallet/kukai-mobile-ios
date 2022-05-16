//
//  UITextView+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/05/2022.
//

import UIKit

public extension UITextView {
	
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
