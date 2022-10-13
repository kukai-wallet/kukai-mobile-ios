//
//  NFTGroupCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit

class NFTGroupCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var chrevonView: UIImageView!
	
	func setClosed() {
		chrevonView.image = UIImage(systemName: "chevron.right")
	}
	
	func setOpen() {
		chrevonView.image = UIImage(systemName: "chevron.down")
	}
}
