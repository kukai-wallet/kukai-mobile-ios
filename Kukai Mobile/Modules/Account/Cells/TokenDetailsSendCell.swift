//
//  TokenDetailsSendCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

class TokenDetailsSendCell: UITableViewCell {
	
	@IBOutlet weak var sendButton: UIButton!
	
	private var gradient = CAGradientLayer()
	
	func setup(data: TokenDetailsSendData) {
		
		if data.isBuyTez {
			var image = UIImage(named: "plus")
			image = image?.resizedImage(Size: CGSize(width: 20, height: 20))
			image = image?.withTintColor(.colorNamed("Brand600"))
			
			sendButton.setImage(image, for: .normal)
			sendButton.configuration?.attributedTitle = AttributedString("Get Tez", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 21)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .leading
			
		} else {
			var image = UIImage(named: "arrow-up-right")
			image = image?.resizedImage(Size: CGSize(width: 20, height: 20))
			image = image?.withTintColor(.colorNamed("Brand600"))
			
			sendButton.setImage(image, for: .normal)
			sendButton.configuration?.attributedTitle = AttributedString("Send", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 21)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .trailing
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = sendButton.addGradientButtonPrimary(withFrame: sendButton.bounds)
	}
}
