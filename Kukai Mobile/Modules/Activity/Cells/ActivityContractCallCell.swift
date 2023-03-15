//
//  ActivityContractCallCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/03/2023.
//

import UIKit
import KukaiCoreSwift

class ActivityContractCallCell: UITableViewCell, UITableViewCellContainerView {
    
	@IBOutlet weak var containerView: UIView!
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var ellipsesImage: UIImageView!
	@IBOutlet weak var chevronImage: UIImageView!
	@IBOutlet weak var timeLabel: UILabel!
	
	var gradientLayer = CAGradientLayer()
	
	func setup(data: TzKTTransactionGroup) {
		/*var color = UIColor.white
		var typeimage = UIImage()
		
		if data.groupType == .receive {
			color = UIColor.colorNamed("TxtB6")
			typeimage = UIImage(named: "ArrowReceive") ?? UIImage.unknownToken()
			typeimage = typeimage.resizedImage(size: CGSize(width: 10, height: 10)) ?? UIImage.unknownToken()
			typeimage = typeimage.withTintColor(color)
			
		} else {
			color = UIColor.colorNamed("Txt10")
			typeimage = UIImage(named: "ArrowSend") ?? UIImage.unknownToken()
			typeimage = typeimage.resizedImage(size: CGSize(width: 10, height: 10)) ?? UIImage.unknownToken()
			typeimage = typeimage.withTintColor(color)
		}
		
		
		transactionTypeIcon.image = typeimage
		type.text = data.groupType == .send ? "Send" : "Receive"
		type.textColor = color
		
		amount.text = (data.primaryToken?.amount.description ?? "") + " \(data.primaryToken?.token.symbol ?? "")"
		toLabel.text = data.groupType == .send ? "To:" : "From:"
		destinationLabel.text = destinationFrom(data)
		timeLabel.text = data.transactions[0].date?.timeAgoDisplay() ?? ""
		 */
	}
	
	func setHasChildren() {
		ellipsesImage.isHidden = true
		chevronImage.isHidden = false
	}
	
	func setHasNoChildren() {
		ellipsesImage.isHidden = false
		chevronImage.isHidden = true
	}
}
