//
//  CollectibleDetailSendCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

protocol CollectibleDetailSendDelegate: AnyObject {
	func sendTapped()
}

class CollectibleDetailSendCell: UICollectionViewCell {

	@IBOutlet weak var sendButton: CustomisableButton!
	
	weak var delegate: CollectibleDetailSendDelegate? = nil
	
	func setup(delegate: CollectibleDetailSendDelegate?) {
		
		sendButton.customButtonType = .primary
		self.delegate = delegate
		
		if let image = sendButton.imageView {
			sendButton.bringSubviewToFront(image)
		}
	}
	
	@IBAction func sendTapped(_ sender: Any) {
		self.delegate?.sendTapped()
	}
}
