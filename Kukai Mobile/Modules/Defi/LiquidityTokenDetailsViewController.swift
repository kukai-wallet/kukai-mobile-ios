//
//  LiquidityTokenDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2022.
//

/*
import UIKit
import Combine

class LiquidityTokenDetailsViewController: UIViewController {
	
	private let viewModel = LiquidityTokenDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var withdrawButton: UIButton!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		amountLabel.text = viewModel.amount
		withdrawButton.isEnabled = viewModel.withdrawEnabled
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal()
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let message):
					self?.hideLoadingModal(completion: nil)
					self?.amountLabel.text = self?.viewModel.amount
					self?.withdrawButton.isEnabled = self?.viewModel.withdrawEnabled == true ? true : false
					
					if let m = message {
						self?.alert(withTitle: "Success", andMessage: m)
					}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	@IBAction func withdrawButtonTapped(_ sender: Any) {
		viewModel.withdrawRewards()
	}
}
*/
