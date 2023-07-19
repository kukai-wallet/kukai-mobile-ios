//
//  BackUpCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2023.
//

import UIKit

class BackUpCell: UITableViewCell {

	@IBOutlet weak var backUpButton: CustomisableButton!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		backUpButton.customButtonType = .secondary
    }
}
