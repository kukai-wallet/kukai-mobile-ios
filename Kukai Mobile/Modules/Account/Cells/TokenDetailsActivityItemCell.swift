//
//  TokenDetailsActivityItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsActivityItemCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var transactionTypeIcon: UIImageView!
	@IBOutlet weak var type: UILabel!
	@IBOutlet weak var amount: UILabel!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var destinationLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var moreButton: UIButton!
	
	var gradientLayer = CAGradientLayer()
	
	func setup(data: TzKTTransactionGroup) {
		var color = UIColor.white
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
	}
	
	private func destinationFrom(_ group: TzKTTransactionGroup) -> String {
		if group.groupType == .send {
			return group.transactions[0].target?.alias ?? group.transactions[0].target?.address.truncateTezosAddress() ?? ""
		} else {
			return group.transactions[0].sender.alias ?? group.transactions[0].sender.address.truncateTezosAddress()
		}
	}
}
