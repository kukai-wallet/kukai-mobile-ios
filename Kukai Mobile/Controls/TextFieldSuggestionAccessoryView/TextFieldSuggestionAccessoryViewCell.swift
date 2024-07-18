//
//  TextFieldSuggestionAccessoryViewCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/04/2023.
//

import UIKit

class TextFieldSuggestionAccessoryViewCell: UICollectionViewCell {
	
	@IBOutlet var label: UILabel!
	
	func setup(withSuggestion: String) {
		label.text = withSuggestion
	}
}
