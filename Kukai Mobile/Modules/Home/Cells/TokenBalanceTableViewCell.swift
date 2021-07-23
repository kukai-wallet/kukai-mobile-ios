//
//  TokenBalanceTableViewCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2021.
//

import UIKit

class TokenBalanceTableViewCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var symbolLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
