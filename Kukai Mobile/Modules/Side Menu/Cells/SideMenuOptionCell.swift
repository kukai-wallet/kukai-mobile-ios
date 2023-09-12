//
//  SideMenuOptionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/03/2023.
//

import UIKit

protocol SideMenuOptionToggleDelegate: AnyObject {
	func sideMenuToggleChangedTo(isOn: Bool, forTitle: String)
}

class SideMenuOptionCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	@IBOutlet weak var toggle: UISwitch?
	
	var containerView: UIView! = UIView()
	var gradientLayer: CAGradientLayer = CAGradientLayer()
	
	weak var delegate: SideMenuOptionToggleDelegate? = nil
	
	@IBAction func toggleChanged(_ sender: Any) {
		delegate?.sideMenuToggleChangedTo(isOn: toggle?.isOn ?? false, forTitle: titleLabel.text ?? "")
	}
}
