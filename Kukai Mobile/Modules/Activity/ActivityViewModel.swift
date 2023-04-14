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
	
	public var forceRefresh = false
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
				if self?.dataSource != nil {
					self?.forceRefresh = true
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
		tableView.register(UINib(nibName: "ActivityContractCallCell", bundle: nil), forCellReuseIdentifier: "ActivityContractCallCell")
		tableView.register(UINib(nibName: "ActivitySubItemCell", bundle: nil), forCellReuseIdentifier: "ActivitySubItemCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let _ = item as? MenuViewController, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityToolbarCell", for: indexPath) as? ActivityToolbarCell {
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				
				if self.expandedIndex == indexPath {
					cell.setOpen()
					
				} else {
					cell.setClosed()
				}
				
				return cell
				
			} else if let obj = item as? TzKTTransaction, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				cell.backgroundColor = .colorNamed("BGActivityBatch")
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let walletAddress = DependencyManager.shared.selectedWalletAddress else {
			state = .failure(.unknown(), "Unbale to locate current wallet")
			return
		}
		
		DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: walletAddress, refreshType: self.forceRefresh ? .forceRefresh : .refreshIfCacheEmpty) { [weak self] error in
			if let err = error {
				self?.state = .failure(err, "Unable to fetch transactions")
				return
			}
			
			var full = DependencyManager.shared.activityService.pendingTransactionGroups
			full.append(contentsOf: DependencyManager.shared.activityService.transactionGroups)
			
			self?.groups = full
			self?.loadGroups()
			self?.state = .success(nil)
		}
	}
	
	private func loadGroups() {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections(Array(0..<self.groups.count+1))
		
		self.currentSnapshot.appendItems([MenuViewController(actions: [], header: nil, sourceViewController: UIViewController())], toSection: 0)
		
		for (index, txGroup) in self.groups.enumerated() {
			self.currentSnapshot.appendItems([txGroup], toSection: index+1)
		}
		
		ds.apply(self.currentSnapshot, animatingDifferences: true)
		
		self.state = .success(nil)
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
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
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityItemCell {
			cell.setOpen()
		}
		
		let group = self.groups[indexPath.section - 1]
		
		currentSnapshot.insertItems(group.transactions, afterItem: group)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityItemCell {
			cell.setClosed()
		}
		
		let group = self.groups[indexPath.section - 1]
		
		currentSnapshot.deleteItems(group.transactions)
	}
	
	private func titleTextFor(token: Token, transaction: TzKTTransaction? = nil) -> String {
		if token.isXTZ() {
			return token.balance.normalisedRepresentation + " XTZ"
			
		} else if let exchangeData = DependencyManager.shared.balanceService.exchangeDataForToken(token) {
			token.balance.decimalPlaces = exchangeData.token.decimals
			return token.balance.normalisedRepresentation + " \(exchangeData.token.symbol)"
			
		} else {
			return token.balance.normalisedRepresentation + " \(transaction?.target?.alias ?? "Token")"
		}
	}
}
