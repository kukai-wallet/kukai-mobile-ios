//
//  SideMenuOptionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/03/2023.
//

import UIKit

class SideMenuOptionCell: UITableViewCell, UITableViewCellThemeUpdated {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	public func themeUpdated() {
		titleLabel.textColor = .colorNamed("Txt6")
		subtitleLabel.textColor = .colorNamed("Txt10")
	}
}
