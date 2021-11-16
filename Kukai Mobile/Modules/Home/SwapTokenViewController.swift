//
//  SwapTokenViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/11/2021.
//

import UIKit
import Combine

class SwapTokenViewController: UITableViewController {
	
	private let viewModel = SwapTokenViewModel()
	private var cancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showActivity(clearBackground: false)
					
				case .failure(_, let errorString):
					self?.hideActivity()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideActivity()
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let pairData = self.viewModel.pairDataFor(indexPath: indexPath) else {
			self.alert(errorWithMessage: "Can't get pricing info")
			return
		}
		
		TransactionService.shared.record(pair: pairData.pair, price: pairData.price)
		self.navigationController?.popViewController(animated: true)
	}
}
