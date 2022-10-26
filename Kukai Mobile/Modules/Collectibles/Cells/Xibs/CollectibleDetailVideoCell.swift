//
//  CollectibleDetailVideoCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit
import AVKit

class CollectibleDetailVideoCell: UICollectionViewCell {

	@IBOutlet weak var placeholderView: UIView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
	
	func setup(avplayerController: AVPlayerViewController) {
		placeholderView.backgroundColor = .clear
		placeholderView.addSubview(avplayerController.view)
		avplayerController.view.frame = placeholderView.frame
	}
}
