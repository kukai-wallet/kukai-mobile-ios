//
//  BatchDetailOperationCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/01/2024.
//

import UIKit

class BatchDetailOperationCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var checkImage: UIImageView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		addressLabel.accessibilityIdentifier = "operation-destination"
		checkImage.accessibilityIdentifier = "operation-selected"
    }

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkImage.isHidden = false
			containerView.borderColor = UIColor.colorNamed("BtnStrokeSecSel1", withAlpha: nil)
		} else {
			checkImage.isHidden = true
			containerView.borderColor = UIColor.colorNamed("BtnStrokeSec1", withAlpha: nil)
		}
	}
}
