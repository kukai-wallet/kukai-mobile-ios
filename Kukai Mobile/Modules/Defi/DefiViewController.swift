//
//  DefiViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//

import UIKit
import Combine

class DefiViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = DefiViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let message):
					self?.hideLoadingModal(completion: nil)
					
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		//TransactionService.shared.removeLiquidityData.position = self.viewModel.position(forIndexPath: indexPath)
		//self.performSegue(withIdentifier: "liquidityDetails", sender: self)
	}
}
