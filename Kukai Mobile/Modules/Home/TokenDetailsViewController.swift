//
//  TokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit

class TokenDetailsViewController: UIViewController {

	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var rateLabel: UILabel!
	
	private let viewModel = TokenDetailsViewModel()
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let token = TransactionService.shared.sendData.chosenToken else {
			return
		}
		
		viewModel.loadOfflineData(token: token)
		
		self.symbolLabel.text = viewModel.symbol
		self.balanceLabel.text = viewModel.balance
		self.fiatLabel.text = viewModel.fiat
		self.rateLabel.text = viewModel.rate
	}
	
	@IBAction func sendTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped(self)
		}
	}
}
