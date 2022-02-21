//
//  EnterAddressComponent.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

@IBDesignable
public class EnterAddressComponent: UIView {
	
	@IBOutlet weak var containerStackView: UIStackView!
	@IBOutlet weak var errorStackView: UIStackView!
	@IBOutlet weak var qrCodeStackView: UIStackView!
	@IBOutlet weak var pasteStackView: UIStackView!
	
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var errorIcon: UIImageView!
	@IBOutlet weak var errorLabel: UILabel!
	
	private let textFieldLeftView = UIView()
	private let nibName = "EnterAddressComponent"
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		guard let view = loadViewFromNib() else { return }
		view.frame = self.bounds
		self.addSubview(view)
		
		setup()
	}
	
	func loadViewFromNib() -> UIView? {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: nibName, bundle: bundle)
		return nib.instantiate(withOwner: self, options: nil).first as? UIView
	}
	
	func setup() {
		textField.borderColor = .lightGray
		textField.borderWidth = 1
		textField.maskToBounds = true
		textField.leftViewMode = .always
		
		let keyboardImage = UIImageView(image: UIImage(systemName: "keyboard"))
		keyboardImage.frame = CGRect(x: 5, y: 0, width: 40, height: 25)
		
		textFieldLeftView.frame = CGRect(x: 0, y: 0, width: 50, height: 25)
		textFieldLeftView.addSubview(keyboardImage)
		
		textField.leftView = textFieldLeftView
	}
	
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		textField.customCornerRadius = textField.frame.height / 2
	}
	
	@IBAction func qrCodeTapped(_ sender: Any) {
		
	}
	
	@IBAction func pasteTapped(_ sender: Any) {
		
	}
	
	
	
	
	/*
	
	// system image names
	//
	// keyboard
	// qrcode
	// text.viewfinder
	//
	// xmark.octagon.fill
	
	*/
}
