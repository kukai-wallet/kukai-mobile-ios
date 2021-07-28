//
//  HomeWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine

class HomeWalletViewController: UIViewController {

	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = HomeWalletViewModel()
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.refresh(animate: true)
		}), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					print("")
					//self?.showActivity(clearBackground: false)
					
				case .failure(_, let errorString):
					self?.hideActivity()
					self?.refreshControl.endRefreshing()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideActivity()
					self?.refreshControl.endRefreshing()
					self?.addressLabel.text = self?.viewModel.walletAddress
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// viewModel.refresh(animate: true)
	}
}
