//
//  UpdateWarningCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/10/2023.
//

import UIKit

class UpdateWarningCell: UITableViewCell {
	
	@IBOutlet weak var updateButton: CustomisableButton!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		updateButton.customButtonType = .secondary
    }
}
