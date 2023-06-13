//
//  WalletConnectViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import Combine
import OSLog

class WalletConnectViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = WalletConnectViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	
	@IBAction func reconnectTapped(_ sender: Any) {

		self.showLoadingModal { [weak self] in
			
			WalletConnectService.shared.reconnect { error in
				
				self?.hideLoadingModal(completion: {
					if let err = error {
						self?.alert(errorWithMessage: "Unable to reconnect: \(err)")
					}
				})
			}
		}
	}
}
