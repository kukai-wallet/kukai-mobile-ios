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
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
				
				case .success(let message):
					//self?.hideLoadingView(completion: nil)
					let _ = ""
					
					if message == CurrencyViewModel.didChangeCurrencyMessage {
						self?.navigationController?.popViewController(animated: true)
					}
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.viewModel.changeCurrency(toIndexPath: indexPath)
	}
}
