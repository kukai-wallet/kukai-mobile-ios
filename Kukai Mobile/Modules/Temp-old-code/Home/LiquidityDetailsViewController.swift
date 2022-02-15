//
//  LiquidityDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2021.
//

import UIKit
import Combine

class LiquidityDetailsViewController: UIViewController {

	@IBOutlet weak var tokenLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var removeTextField: UITextField!
	@IBOutlet weak var returnedXTZTextField: UITextField!
	@IBOutlet weak var returnedTokenTextField: UITextField!
	@IBOutlet weak var returnedTokenLabel: UILabel!
	
	@IBOutlet weak var pendingRewardsLabel: UILabel!
	@IBOutlet weak var pendingRewardsTextField: UITextField!
	@IBOutlet weak var withdrawButton: UIButton!
	
	private let viewModel = LiquidityDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = false
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateUI()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let message):
					self?.hideLoadingModal(completion: nil)
					self?.updateUI()
					
					if let m = message {
						self?.alert(withTitle: "Success", andMessage: m)
					}
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		//self.viewModel.refresh(animate: true, successMessage: nil)
	}
	
	func updateUI() {
		self.tokenLabel.text = self.viewModel.token
		self.amountLabel.text = self.viewModel.amount
		self.returnedTokenLabel.text = self.viewModel.token
		self.returnedXTZTextField.text = self.viewModel.xtzReturned
		self.returnedTokenTextField.text = self.viewModel.tokenReturned
		
		if viewModel.pendingRewardsSupported {
			self.pendingRewardsLabel.isHidden = false
			self.pendingRewardsTextField.isHidden = false
			self.withdrawButton.isHidden = false
			
			self.pendingRewardsTextField.text = self.viewModel.pendingRewardsDisplay
			
		} else {
			self.pendingRewardsLabel.isHidden = true
			self.pendingRewardsTextField.isHidden = true
			self.withdrawButton.isHidden = true
		}
	}
	
	/*
	@IBAction func checkPricetapped(_ sender: Any) {
		self.viewModel.checkPrice(forEnteredLiquidity: removeTextField.text ?? "")
	}
	
	@IBAction func removeLiquidityTapped(_ sender: Any) {
		self.viewModel.removeLiquidity()
	}
	
	@IBAction func withdrawTapped(_ sender: Any) {
		self.viewModel.withdrawRewards()
	}
	*/
}
