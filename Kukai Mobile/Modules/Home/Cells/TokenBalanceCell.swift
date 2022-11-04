//
//  TokenBalanceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class TokenBalanceCell: UITableViewCell {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var rateLabel: UILabel!
	@IBOutlet weak var valuelabel: UILabel!
	
	private var gradient = CAGradientLayer()
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		gradient.removeFromSuperlayer()
		
		gradient.colors = [ UIColor(red: 0.758, green: 0.758, blue: 0.85, alpha: 0.1).cgColor, UIColor(red: 0.829, green: 0.829, blue: 0.904, alpha: 0.05).cgColor]
		gradient.locations = [0.36, 0.93]
		gradient.startPoint = CGPoint(x: 0.1, y: 0.5)
		gradient.endPoint = CGPoint(x: 0.9, y: 0.5)
		gradient.frame = CGRect(x: 0, y: 0, width: containerView.frame.width, height: containerView.frame.height)
		
		containerView.layer.insertSublayer(gradient, at: 0)
	}
}
