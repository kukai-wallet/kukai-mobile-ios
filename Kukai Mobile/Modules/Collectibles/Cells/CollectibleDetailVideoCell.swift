//
//  CollectibleDetailVideoCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/10/2022.
//

import UIKit
import AVKit

class CollectibleDetailVideoCell: UICollectionViewCell {
	
	@IBOutlet weak var placeholderView: UIView!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let width = UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2)
		let targetSize = CGSize(width: width, height: 0)
		let estimatedSize = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		layoutAttributes.frame.size = CGSize(width: estimatedSize.width, height: estimatedSize.height.rounded(.up))
		
		return layoutAttributes
	}
	
	func setup(avplayerController: AVPlayerViewController) {
		placeholderView.backgroundColor = .clear
		placeholderView.addSubview(avplayerController.view)
		avplayerController.view.frame = placeholderView.frame
	}
}
