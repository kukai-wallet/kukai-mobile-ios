//
//  CollectibleDetailSendCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailSendCell: UICollectionViewCell {

	@IBOutlet weak var sendButton: UIButton!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	func setup(target: Any?, action: Selector) {
		let _ = sendButton.addGradientButtonPrimary(withFrame: sendButton.bounds)
		sendButton.addTarget(target, action: action, for: .touchUpInside)
	}
}
