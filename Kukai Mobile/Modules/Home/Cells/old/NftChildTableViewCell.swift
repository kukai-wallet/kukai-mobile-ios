//
//  NftChildTableViewCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2021.
//

import UIKit

class NftChildTableViewCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
