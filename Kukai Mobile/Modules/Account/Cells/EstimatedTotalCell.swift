//
//  EstimatedTotalCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

protocol EstimatedTotalCellDelegate: AnyObject {
	func totalEstiamtedInfoTapped()
}

class EstimatedTotalCell: UITableViewCell {

	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var totalEstButton: UIButton!
	
	public weak var delegate: EstimatedTotalCellDelegate? = nil
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	@IBAction func totalEstimatedTapped(_ sender: Any) {
		delegate?.totalEstiamtedInfoTapped()
	}
}
