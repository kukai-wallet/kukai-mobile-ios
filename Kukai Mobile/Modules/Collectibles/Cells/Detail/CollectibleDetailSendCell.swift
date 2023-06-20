//
//  CollectibleDetailSendCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailSendCell: UICollectionViewCell {

	@IBOutlet weak var sendButton: CustomisableButton!
	
	func setup(target: Any?, action: Selector) {
		
		sendButton.customButtonType = .primary
		
		if let image = sendButton.imageView {
			sendButton.bringSubviewToFront(image)
		}
		sendButton.addTarget(target, action: action, for: .touchUpInside)
	}
}
