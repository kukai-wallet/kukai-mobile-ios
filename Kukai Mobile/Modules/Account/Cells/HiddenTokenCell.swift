//
//  HiddenTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit
import SDWebImage

class HiddenTokenCell: UITableViewCell {
	
	@IBOutlet weak var hiddenIcon: UIImageView!
	@IBOutlet weak var tokenIcon: SDAnimatedImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var containerView: GradientView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	override func prepareForReuse() {
		tokenIcon.sd_cancelCurrentImageLoad()
		tokenIcon.image = nil
	}
}
