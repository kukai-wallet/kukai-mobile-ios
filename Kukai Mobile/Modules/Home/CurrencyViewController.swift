//
//  CurrencyViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/02/2022.
//

import UIKit
import Combine

class CurrencyViewController: UITableViewController {
	
	private let viewModel = CurrencyViewModel()
	private var cancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let code = viewModel.code(forIndexPath: indexPath)
		
		self.showLoadingView(completion: nil)
		DependencyManager.shared.coinGeckoService.setSelectedCurrency(currency: code) { error in
			if let e = error {
				self.alert(errorWithMessage: "Unable to change currency: \(e)")
				self.hideLoadingView(completion: nil)
				return
			}
			
			guard let walletAddress = DependencyManager.shared.selectedWallet?.address else {
				self.alert(errorWithMessage: "Can't find wallet details)")
				self.hideLoadingView(completion: nil)
				return
			}
			
			DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: walletAddress) { error in
				if let e = error {
					self.alert(errorWithMessage: "Unable to update balances: \(e)")
					self.hideLoadingView(completion: nil)
					return
				}
				
				self.navigationController?.popViewController(animated: true)
				self.hideLoadingView(completion: nil)
			}
		}
	}
}
