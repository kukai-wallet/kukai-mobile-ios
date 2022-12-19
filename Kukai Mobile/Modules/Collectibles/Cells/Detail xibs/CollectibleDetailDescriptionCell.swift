//
//  CollectibleDetailDescriptionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit

class CollectibleDetailDescriptionCell: UICollectionViewCell {

	@IBOutlet weak var textView: UITextView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup(withString string: String) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineHeightMultiple = 1.15
		
		let attributedtext = NSAttributedString(string: string, attributes: [
			NSAttributedString.Key.foregroundColor: UIColor(named: "Grey600") ?? UIColor.black,
			NSAttributedString.Key.font: UIFont.custom(ofType: .regular, andSize: 15),
			NSAttributedString.Key.paragraphStyle: paragraphStyle
		])
		
		textView.backgroundColor = .clear
		textView.attributedText = attributedtext
		textView.textContainerInset = UIEdgeInsets.zero
		textView.textContainer.lineFragmentPadding = 0
	}
}
