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
			NSAttributedString.Key.foregroundColor: UIColor(named: "Txt6") ?? UIColor.black,
			NSAttributedString.Key.font: UIFont.custom(ofType: .regular, andSize: 14),
			NSAttributedString.Key.paragraphStyle: paragraphStyle
		])
		
		//textView.dataDetectorTypes = .link
		textView.backgroundColor = .clear
		textView.attributedText = attributedtext
		textView.linkTextAttributes = [.foregroundColor: UIColor.colorNamed("TxtLink")]
		textView.textContainerInset = UIEdgeInsets.zero
		textView.textContainer.lineFragmentPadding = 0
	}
}
