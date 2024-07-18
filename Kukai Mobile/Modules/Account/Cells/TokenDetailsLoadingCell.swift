//
//  TokenDetailsLoadingCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

class TokenDetailsLoadingCell: UITableViewCell {
	
	@IBOutlet weak var activityView: UIActivityIndicatorView!
	
	func setup() {
		activityView.startAnimating()
	}
}
