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
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					break
					
				case .failure(_, let errorString):
					//self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let message):
					//self?.hideLoadingModal(completion: nil)
					
					if let m = message {
						self?.alert(withTitle: "Success", andMessage: m)
					}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isVisible = true
		viewModel.refresh(animate: false)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let selectedPosition = self.viewModel.position(forIndexPath: indexPath)
		if selectedPosition.exchange.name == .quipuswap {
			TransactionService.shared.liquidityDetails.selectedPosition = selectedPosition
			self.performSegue(withIdentifier: "liquidityDetails", sender: self)
			
		} else {
			self.alert(errorWithMessage: "Token details are only available for Quipuswap tokens")
		}
	}
}
