//
//  HomeWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine
import KukaiCoreSwift

class HomeWalletViewController: UIViewController {

	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = HomeWalletViewModel()
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
					self?.addressLabel.text = self?.viewModel.walletAddress
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
}
