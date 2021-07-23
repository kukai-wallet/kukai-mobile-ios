//
//  HomeWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class HomeWalletViewController: UIViewController {

	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let address = WalletCacheService().fetchPrimaryWallet()?.address
		addressLabel.text = address
    }
}


/*
class TableViewTest: UITableViewController {
	private var viewModel = ProfileViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.dataSource = viewModel.makeDataSource(withTableView: self.tableView)
		
		cancellable = viewModel.$state.sink { state in
			
			switch state {
				case .loading:
					print("loading")
					
				case .failure(let error, let errorString):
					print("failure: \(errorString), \(error)")
					
				case .success:
					print("success")
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(dataSource: tableView.dataSource, animate: true)
	}
}
*/
