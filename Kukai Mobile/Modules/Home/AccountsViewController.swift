//
//  AccountsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class AccountsViewController: UIViewController {
	
	public let viewModel = AccountsViewModel()
	private var cancellable: AnyCancellable?
	
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Setup data
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			guard let self = self else { return }
			
			switch state {
				case .loading:
					let _ = ""
					
				case .success(_):
					
					// Always seems to be an extra section, so 1 section left = no content
					if self.viewModel.dataSource?.numberOfSections(in: self.tableView) == 1 {
						self.closeAndBackToStart()
					}
					
				case .failure(_, let message):
					self.alert(withTitle: "Error", andMessage: message)
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)
		
		viewModel.refresh(animate: true)
	}
	
	public func refeshWallets() {
		viewModel.refresh(animate: true)
	}
	
	func closeAndBackToStart() {
		self.presentingViewController?.dismiss(animated: true)
		let _ = WalletCacheService().deleteCacheAndKeys()
		DependencyManager.shared.balanceService.deleteAllCachedData()
		TransactionService.shared.resetState()
		DependencyManager.shared.tzktClient.stopListeningForAccountChanges()
		
		(self.presentingViewController as? UINavigationController)?.popToRootViewController(animated: true)
	}
}

extension AccountsViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedIndex = DependencyManager.shared.selectedWalletIndex
		
		// If we want to select the parent wallet, its WalletIndex(parent: x, child: nil)
		// Selecting the first child, its WalletIndex(parent: x, child: 0)
		// Because the parent is the first cell in each section, we need to add or subtract 1 from the indexPath.row when dealing with `selectedWalletIndex`
		if indexPath.section != selectedIndex.parent || indexPath.row != (selectedIndex.child ?? -1) + 1 {
			(tableView.cellForRow(at: indexPath) as? AccountBasicCell)?.setBorder(true)
			
			DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: indexPath.section, child: (indexPath.row == 0 ? nil : indexPath.row-1))
			self.presentingViewController?.dismiss(animated: true)
		}
	}
}
