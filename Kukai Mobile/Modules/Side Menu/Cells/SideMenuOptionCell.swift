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

class SideMenuOptionCell: UITableViewCell {
	
	@IBOutlet weak var customContainerView: GradientView? // cell needs container view on 1 screen, and being used by many, adding custom for 1 screen
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	@IBOutlet weak var toggle: UISwitch?
	
	var containerView: UIView! = GradientView(gradientType: .tableViewCell)
	
	weak var delegate: SideMenuOptionToggleDelegate? = nil
	
	override func awakeFromNib() {
		super.awakeFromNib()
		customContainerView?.gradientType = .tableViewCell
	}
	
	@IBAction func toggleChanged(_ sender: Any) {
		delegate?.sideMenuToggleChangedTo(isOn: toggle?.isOn ?? false, forTitle: titleLabel.text ?? "")
	}
	
	func setup(title: String, subtitle: String, subtitleIsWarning: Bool) {
		self.titleLabel.text = title
		self.subtitleLabel.text = subtitle
		
		if subtitleIsWarning {
			self.subtitleLabel.textColor = .colorNamed("TxtAlert4")
		} else {
			self.subtitleLabel.textColor = .colorNamed("Txt10")
		}
	}
}
