//
//  LiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//
/*
import UIKit

class LiquidityViewController: UIViewController {
	
	@IBOutlet weak var addContainer: UIView!
	@IBOutlet weak var removeContainer: UIView!
	@IBOutlet weak var settingsButton: UIButton!
	@IBOutlet weak var segmentedButton: UISegmentedControl!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		showAdd()
    }
	
	@IBAction func segmentedButtonChanged(_ sender: Any) {
		if segmentedButton.selectedSegmentIndex == 0 {
			showAdd()
		} else {
			showRemove()
		}
	}
	
	func showAdd() {
		addContainer.isHidden = false
		removeContainer.isHidden = true
		
		TransactionService.shared.currentTransactionType = .addLiquidity
	}
	
	func showRemove() {
		addContainer.isHidden = true
		removeContainer.isHidden = false
		
		TransactionService.shared.currentTransactionType = .removeLiquidity
	}
}
*/

