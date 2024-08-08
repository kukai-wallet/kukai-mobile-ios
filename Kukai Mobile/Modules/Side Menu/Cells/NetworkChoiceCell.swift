//
//  NetworkChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/06/2023.
//

import UIKit

class NetworkChoiceCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var networkLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var checkedImage: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkedImage.image = UIImage(named: "btnChecked")
		} else {
			checkedImage.image = UIImage(named: "btnUnchecked")
		}
	}
}
