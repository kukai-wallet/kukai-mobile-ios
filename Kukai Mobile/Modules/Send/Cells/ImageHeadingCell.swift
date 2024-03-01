//
//  ImageHeadingCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit

class ImageHeadingCell: UITableViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var headingLabel: UILabel!
	@IBOutlet weak var lessButton: CustomisableButton!
	
	public weak var delegate: AccountsSectionHeaderCellDelegate? = nil
	
	@IBAction func lessTapped(_ sender: Any) {
		delegate?.lessTapped()
	}
}
