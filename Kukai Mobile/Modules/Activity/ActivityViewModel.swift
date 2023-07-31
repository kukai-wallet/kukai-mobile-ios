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
	var forceRefresh = false
	public var menuVc: MenuViewController? = nil
	
	public var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var groups: [TzKTTransactionGroup] = []
	private var previousAddress: String = ""
	
	private var bag = [AnyCancellable]()
	private var selectedWalletAddress = DependencyManager.shared.selectedWalletAddress
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressLoaded
			.dropFirst()
			.sink { [weak self] address in
				if DependencyManager.shared.selectedWalletAddress == address {
					self?.forceRefresh = true
					
					if self?.isVisible == true {
						self?.refresh(animate: true)
					}
				}
			}.store(in: &bag)
		
		DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && self?.isVisible == true && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "ActivityItemCell", bundle: nil), forCellReuseIdentifier: "ActivityItemCell")
		tableView.register(UINib(nibName: "ActivityItemContractCell", bundle: nil), forCellReuseIdentifier: "ActivityItemContractCell")
		tableView.register(UINib(nibName: "ActivityItemBatchCell", bundle: nil), forCellReuseIdentifier: "ActivityItemBatchCell")
		tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let _ = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityToolbarCell", for: indexPath) as? ActivityToolbarCell {
				cell.backgroundColor = .clear
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
				cell.backgroundColor = .clear
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				cell.backgroundColor = .clear
				return cell
				
			} else if let obj = item as? TzKTTransaction, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				cell.backgroundColor = .colorNamed("BGActivityBatch")
				return cell
				
			} else if let _ = item as? LoadingContainerCellObject, let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingContainerCell", for: indexPath) as? LoadingContainerCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
				
			} else if let _ = item as? Int {
				return tableView.dequeueReusableCell(withIdentifier: "BatchBottomPadding", for: indexPath)
				
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "GhostnetWarningCell", for: indexPath)
				cell.backgroundColor = .clear
				return cell
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		if self.expandedIndex != nil {
			self.forceRefresh = true
			self.expandedIndex = nil
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
		
		DependencyManager.shared.balanceService.fetch(records: [BalanceService.FetchRequestRecord(address: address, type: .refreshEverything)])
	}
	
	private func loadGroups(animate: Bool) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		// Build snapshot
		let isTestnet = DependencyManager.shared.currentNetworkType == .testnet
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		var data: [[AnyHashable]] = [[]]
		
		if isTestnet {
			data[0] = [GhostnetWarningCellObj(), "Activity"]
		} else {
			data[0] = ["Activity"]
		}
		
		
		// If needs shimmers
		let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		if DependencyManager.shared.balanceService.hasBeenFetched(forAddress: selectedAddress) {
			for txGroup in self.groups {
				data.append(contentsOf: [[txGroup]])
			}
		} else {
			data.append(contentsOf: [[LoadingContainerCellObject()]])
			data.append(contentsOf: [[LoadingContainerCellObject()]])
			data.append(contentsOf: [[LoadingContainerCellObject()]])
		}
		
		
		// Apply to snapshot
		currentSnapshot.appendSections(Array(0..<data.count))
		for (index, array) in data.enumerated() {
			currentSnapshot.appendItems(array, toSection: index)
		}
		
		// Load
		if forceRefresh {
			ds.applySnapshotUsingReloadData(self.currentSnapshot)
			self.forceRefresh = false
			
		} else {
			ds.apply(self.currentSnapshot, animatingDifferences: animate)
		}
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		guard let group = dataSource?.itemIdentifier(for: indexPath) as? TzKTTransactionGroup else {
			return
		}
		
		if group.transactions.count == 1 {
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
		if let item = dataSource?.itemIdentifier(for: indexPath) as? TzKTTransactionGroup {
			return (item.transactions.first?.status ?? .applied) == .unconfirmed
		}
		
		return false
	}
	
	private func openGroup(forTableView tableView: UITableView?, atIndexPath indexPath: IndexPath) {
		if let cell = tableView?.cellForRow(at: indexPath) as? ActivityItemBatchCell {
			cell.setOpen()
		}
		
		let parent = self.groups[indexPath.section - 1]
		var items: [AnyHashable] = parent.transactions
		items.append(1) // add bottom batch padding cell, as for some reason viewForFooterInSection is not being called on insert, but is on delete
		
		currentSnapshot.insertItems(items, afterItem: parent)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityItemBatchCell {
			cell.setClosed()
		}
		
		let parent = self.groups[indexPath.section - 1]
		var items: [AnyHashable] = parent.transactions
		items.append(1)
		
		currentSnapshot.deleteItems(items)
	}
}
