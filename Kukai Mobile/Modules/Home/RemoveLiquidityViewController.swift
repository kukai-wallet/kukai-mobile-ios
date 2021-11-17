//
//  RemoveLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/11/2021.
//

import UIKit
import Combine

class RemoveLiquidityViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = RemoveLiquidityViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showActivity(clearBackground: false)
					
				case .failure(_, let errorString):
					self?.hideActivity()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let message):
					self?.hideActivity()
					
					if let m = message {
						self?.alert(withTitle: "Success", andMessage: m)
					}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let position = self.viewModel.position(forIndexPath: indexPath)
		
		self.alert(withTitle: "Remove?", andMessage: "Are you sure you want to remove liquidity for \(position.token.symbol) - \(position.exchange.name.rawValue)", okText: "Ok", okAction: { [weak self] action in
			self?.viewModel.removeLiquidity(forIndexPath: indexPath)
			
		}, cancelText: "Cancel") { action in
			
		}
	}
}
