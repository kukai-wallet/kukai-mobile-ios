//
//  ActivityViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class ActivityViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	public var isVisible = false
	public var menuVc: MenuViewController? = nil
	
	public var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var groups: [TzKTTransactionGroup] = []
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	private var selectedWalletAddress = DependencyManager.shared.selectedWalletAddress
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil && self?.isVisible == true {
					self?.refresh(animate: true)
				}
			}
	}
	
	deinit {
		accountDataRefreshedCancellable?.cancel()
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "ActivityItemCell", bundle: nil), forCellReuseIdentifier: "ActivityItemCell")
		tableView.register(UINib(nibName: "ActivityItemContractCell", bundle: nil), forCellReuseIdentifier: "ActivityItemContractCell")
		tableView.register(UINib(nibName: "ActivityItemBatchCell", bundle: nil), forCellReuseIdentifier: "ActivityItemBatchCell")
		tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let _ = item as? MenuViewController, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityToolbarCell", for: indexPath) as? ActivityToolbarCell {
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, obj.transactions.count > 1, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemBatchCell", for: indexPath) as? ActivityItemBatchCell {
				cell.setup(data: obj)
				
				if self.expandedIndex == indexPath {
					cell.setOpen()
					
				} else {
					cell.setClosed()
				}
				
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, obj.groupType == .contractCall, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemContractCell", for: indexPath) as? ActivityItemContractCell {
				cell.setup(data: obj.transactions[0])
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item as? TzKTTransaction, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				cell.backgroundColor = .colorNamed("BGActivityBatch")
				return cell
				
			} else {
				return tableView.dequeueReusableCell(withIdentifier: "GhostnetWarningCell", for: indexPath)
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		let currentAddress = DependencyManager.shared.selectedWalletAddress
		var full = DependencyManager.shared.activityService.pendingTransactionGroups.filter({ $0.transactions.first?.sender.address == currentAddress })
		full.append(contentsOf: DependencyManager.shared.activityService.transactionGroups)
			
		self.groups = full
		self.loadGroups(animate: animate)
		self.state = .success(nil)
	}
	
	func pullToRefresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWalletAddress else {
			state = .failure(.unknown(), "Unable to locate current wallet")
			return
		}
		
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address, isSelectedAccount: true, refreshType: .refreshEverything) { [weak self] error in
			guard let self = self else { return }
			
			if let e = error {
				self.state = .failure(e, "Unable to fetch data")
			}
			
			self.refresh(animate: animate)
			
			// Return success
			self.state = .success(nil)
		}
	}
	
	private func loadGroups(animate: Bool) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		
		let isTestnet = DependencyManager.shared.currentNetworkType == .testnet
		
		if isTestnet {
			currentSnapshot.appendSections(Array(0..<self.groups.count + 2))
			self.currentSnapshot.appendItems([
				GhostnetWarningCellObj(),
				MenuViewController(actions: [], header: nil, sourceViewController: UIViewController())
			], toSection: 0)
			
		} else {
			currentSnapshot.appendSections(Array(0..<self.groups.count + 1))
			self.currentSnapshot.appendItems([MenuViewController(actions: [], header: nil, sourceViewController: UIViewController())], toSection: 0)
		}
		
		for (index, txGroup) in self.groups.enumerated() {
			self.currentSnapshot.appendItems([txGroup], toSection: index+1)
		}
		
		ds.apply(self.currentSnapshot, animatingDifferences: animate)
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		if groups[indexPath.section-1].transactions.count == 1 {
			return
		}
		
		if expandedIndex == nil {
			expandedIndex = indexPath
			self.openGroup(forTableView: tableView, atIndexPath: indexPath)
			
		} else if expandedIndex == indexPath {
			expandedIndex = nil
			self.closeGroup(forTableView: tableView, atIndexPath: indexPath)
			
		} else if let previousIndex = expandedIndex, previousIndex != indexPath {
			self.openGroup(forTableView: tableView, atIndexPath: indexPath)
			self.closeGroup(forTableView: tableView, atIndexPath: previousIndex)
			expandedIndex = indexPath
		}
		
		ds.apply(currentSnapshot, animatingDifferences: true)
	}
	
	public func isUnconfirmed(indexPath: IndexPath) -> Bool {
		if indexPath.section == 0 {
			return false
		}
		
		return (self.groups[indexPath.section - 1].transactions.first?.status ?? .applied) == .unconfirmed
	}
	
	private func openGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityItemBatchCell {
			cell.setOpen()
		}
		
		let group = self.groups[indexPath.section - 1]
		
		currentSnapshot.insertItems(group.transactions, afterItem: group)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityItemBatchCell {
			cell.setClosed()
		}
		
		let group = self.groups[indexPath.section - 1]
		
		currentSnapshot.deleteItems(group.transactions)
	}
}
