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
		sendButton.configuration?.attributedTitle = AttributedString("Send", attributes: AttributeContainer( [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 20)] ))
		sendButton.configuration?.imagePadding = 8
		sendButton.configuration?.imagePlacement = .trailing
		sendButton.isEnabled = !data.isDisabled
	}
}
