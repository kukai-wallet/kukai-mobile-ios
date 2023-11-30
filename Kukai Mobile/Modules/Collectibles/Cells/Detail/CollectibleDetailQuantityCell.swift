//
//  CollectibleDetailQuantityCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2023.
//

import UIKit

class CollectibleDetailQuantityCell: UICollectionViewCell {

	@IBOutlet weak var onSaleIndicator: UIButton!
	@IBOutlet weak var audioIndicator: UIImageView!
	@IBOutlet weak var interactableModelIndicator: UIImageView!
	@IBOutlet weak var mediaIndicator: UIImageView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	func setup(data: QuantityContent) {
		onSaleIndicator.isHidden = !data.isOnSale
		audioIndicator.isHidden = !data.isAudio
		interactableModelIndicator.isHidden = !data.isInteractableModel
		mediaIndicator.isHidden = !data.isVideo
		
		quantityLabel.text = data.quantity
	}
}
