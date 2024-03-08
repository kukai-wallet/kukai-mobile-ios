//
//  TokenDetailsSendCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

class TokenDetailsSendCell: UITableViewCell {
	
	@IBOutlet weak var sendButton: CustomisableButton!
	
	func setup(data: TokenDetailsSendData) {
		
		sendButton.customButtonType = .primary
		
		if data.isBuyTez {
			var image = UIImage(named: "Plus")
			image = image?.resizedImage(size: CGSize(width: 15, height: 15))
			image = image?.withTintColor(.colorNamed("TxtBtnPrim1"))
			
			sendButton.setImage(image, for: .normal)
			sendButton.configuration?.attributedTitle = AttributedString("Get Tez (XTZ)", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .leading
			
		} else {
			sendButton.configuration?.attributedTitle = AttributedString("Send", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)] ))
			sendButton.configuration?.imagePadding = 8
			sendButton.configuration?.imagePlacement = .trailing
		}
		
		sendButton.isEnabled = !data.isDisabled
	}
}
