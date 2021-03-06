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
					self?.showLoadingModal(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingModal(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		TransactionService.shared.record(exchange: self.viewModel.exchange(forIndexPath: indexPath))
		self.navigationController?.popViewController(animated: true)
	}
}
