//
//  ChooseLiquidityTokenViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/08/2022.
//

import UIKit
import Combine

class ChooseLiquidityTokenViewController: UITableViewController {
	
	private let viewModel = DefiViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					print("")
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingModal(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: true)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		TransactionService.shared.removeLiquidityData.position = self.viewModel.position(forIndexPath: indexPath)
		self.navigationController?.popViewController(animated: true)
	}
}
