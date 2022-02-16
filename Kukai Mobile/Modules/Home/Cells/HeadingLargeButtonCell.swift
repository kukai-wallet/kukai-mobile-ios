//
//  HeadingLargeButtonCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class HeadingLargeButtonCell: UITableViewCell {

	@IBOutlet weak var headingLabel: UILabel!
	@IBOutlet weak var button: UIButton!
	
	public func setup(heading: String, buttonTitle: String) {
		self.headingLabel.text = heading
		self.button.setTitle(buttonTitle, for: .normal)
	}
}
