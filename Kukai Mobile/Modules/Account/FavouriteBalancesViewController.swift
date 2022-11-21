//
//  FavouriteBalancesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit

class FavouriteBalancesViewController: UIViewController {

	@IBOutlet weak var reOrderButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var subHeadingLabel: UILabel!
	
	@IBOutlet var subHeadingBottomConstraint: NSLayoutConstraint!
	@IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
	
	private var isReOrder = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func reOrderButtonTapped(_ sender: Any) {
		isReOrder = !isReOrder
		
		if isReOrder {
			reOrderButton.setTitle("Done", for: .normal)
			subHeadingLabel.isHidden = true
			subHeadingBottomConstraint.isActive = false
			self.view.layoutIfNeeded()
			
		} else {
			reOrderButton.setTitle("Re-Order", for: .normal)
			subHeadingLabel.isHidden = false
			subHeadingBottomConstraint.isActive = true
			self.view.layoutIfNeeded()
		}
	}
}
