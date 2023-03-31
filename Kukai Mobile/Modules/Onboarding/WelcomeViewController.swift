//
//  WelcomeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

class WelcomeViewController: UIViewController {
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		DependencyManager.shared.setDefaultMainnetURLs()
	}
	
	
	/*
	 feeButton.configuration?.imagePlacement = .trailing
	 feeButton.configuration?.imagePadding = 6
	 feeButton.isEnabled = false
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	private var gradient = CAGradientLayer()
	
	func setup(data: TokenDetailsSendData) {
		
		if data.isBuyTez {
			var image = UIImage(named: "Plus")
			image = image?.resizedImage(size: CGSize(width: 15, height: 15))
			image = image?.withTintColor(.colorNamed("TxtBtnPrim1"))
			
			sendButton.setImage(image, for: .normal)
			sendButton.configuration?.attributedTitle = AttributedString("Get Tez", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .leading
			
		} else {
			sendButton.configuration?.attributedTitle = AttributedString("Send", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .trailing
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = sendButton.addGradientButtonPrimary(withFrame: sendButton.bounds)
	}
	*/
	
}
