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
	//public var visibleIndexPaths: [IndexPath] = []
	
	private var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var groups: [TzKTTransactionGroup] = []
	private static let cachedFileName = "ActivityViewModel-transactions"
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil {
					ActivityViewModel.deleteCache()
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
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self, let walletAddress = DependencyManager.shared.selectedWallet?.address else { return UITableViewCell() }
			
			if let obj = item as? TzKTTransactionGroup, obj.groupType != .exchange, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityGenericCell", for: indexPath) as? ActivityGenericCell {
				
				if let primaryToken = obj.primaryToken {
					cell.titleLabel.text = self.titleTextFor(tokenDetails: primaryToken, transaction: obj.transactions.first)
					
				} else if let entrypoint = obj.entrypointCalled {
					cell.titleLabel.text = "Called: \(entrypoint)"
					
				} else if obj.groupType == .delegate {
					cell.titleLabel.text = "Changed Delegate"
					
				} else if obj.groupType == .reveal {
					cell.titleLabel.text = "Revealed"
					
				} else if obj.groupType == .unknown {
					cell.titleLabel.text = "Unknown"
				}
				
				if obj.groupType == .receive {
					cell.prefixLabel.text = "From:"
					cell.addressLabel.text = (obj.transactions.last?.sender.alias ?? obj.transactions.last?.sender.address) ?? "-"
					cell.setReceived()
					
				} else {
					cell.prefixLabel.text = "To:"
					cell.addressLabel.text = (obj.transactions.last?.target?.alias ?? obj.transactions.last?.target?.address) ?? "-"
					cell.setSent()
				}
				
				if obj.transactions.count > 1 {
					cell.setHasChildren()
					
				} else {
					cell.setHasNoChildren()
				}
				
				cell.date = obj.transactions.last?.date
				
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, obj.groupType == .exchange, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityExchangeCell", for: indexPath) as? ActivityExchangeCell {
				
				if let primaryToken = obj.primaryToken, let secondaryToken = obj.secondaryToken {
					cell.sentLabel.text = self.titleTextFor(tokenDetails: primaryToken)
					cell.receivedLabel.text = self.titleTextFor(tokenDetails: secondaryToken)
				}
				
				cell.date = obj.transactions.last?.date
				
				return cell
				
			} else if let obj = item as? TzKTTransaction, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivitySubItemCell", for: indexPath) as? ActivitySubItemCell {
				
				if let entrypoint = obj.getEntrypoint(), entrypoint == "transfer", let tokenData = obj.getFaTokenTransferData() {
					if obj.getTokenTransferDestination() == walletAddress {
						cell.titleLabel.text = "Received: \(self.titleTextFor(tokenDetails: tokenData, transaction: obj))"
						
					} else {
						cell.titleLabel.text = "Sent: \(self.titleTextFor(tokenDetails: tokenData, transaction: obj))"
					}
					
				} else if let entrypoint = obj.getEntrypoint() {
					cell.titleLabel.text = "Called: \(entrypoint)"
					
				} else if obj.sender.address == walletAddress && obj.amount != .zero() {
					cell.titleLabel.text = "Sent: \(obj.amount.normalisedRepresentation) XTZ"
					
				} else if obj.sender.address != walletAddress && obj.amount != .zero() {
					cell.titleLabel.text = "Received: \(obj.amount.normalisedRepresentation) XTZ"
					
				} else {
					cell.titleLabel.text = "Unknown Operation"
				}
				
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
		
		guard let walletAddress = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find wallet")
			return
		}
		
		
		if !forceRefresh, currentSnapshot.numberOfItems == 0, let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityViewModel.cachedFileName) {
			self.groups = cachedGroups
			self.loadGroups()
			
		} else if forceRefresh || currentSnapshot.numberOfItems == 0 {
			DependencyManager.shared.tzktClient.fetchTransactions(forAddress: walletAddress) { [weak self] transactions in
				guard let self = self else {
					self?.state = .success(nil)
					return
				}
				
				self.forceRefresh = false
				self.groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: walletAddress)
				let _ = DiskService.write(encodable: self.groups, toFileName: ActivityViewModel.cachedFileName)
				
				self.loadGroups()
			}
			
		} else {
			state = .success(nil)
		}
	}
	
	private func loadGroups() {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		self.currentSnapshot.appendSections(Array(0..<self.groups.count))
		
		for (index, txGroup) in self.groups.enumerated() {
			self.currentSnapshot.appendItems([txGroup], toSection: index)
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
	
	private func openGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityExchangeCell {
			cell.setOpen()
		}
		
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityGenericCell {
			cell.setOpen()
		}
		
		let group = self.groups[indexPath.section]
		
		currentSnapshot.insertItems(group.transactions, afterItem: group)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityExchangeCell {
			cell.setClosed()
		}
		
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityGenericCell {
			cell.setClosed()
		}
		
		let group = self.groups[indexPath.section]
		
		currentSnapshot.deleteItems(group.transactions)
	}
	
	private func titleTextFor(tokenDetails: TzKTTransactionGroup.TokenDetails, transaction: TzKTTransaction? = nil) -> String {
		if tokenDetails.isXTZ() {
			return tokenDetails.amount.normalisedRepresentation + " XTZ"
			
		} else if let exchangeData = DependencyManager.shared.balanceService.exchangeDataForToken(tokenDetails.token) {
			tokenDetails.amount.decimalPlaces = exchangeData.token.decimals
			return tokenDetails.amount.normalisedRepresentation + " \(exchangeData.token.symbol)"
			
		} else {
			return tokenDetails.amount.normalisedRepresentation + " \(transaction?.target?.alias ?? "Token")"
		}
	}
	
	public static func deleteCache() {
		let _ = DiskService.delete(fileName: ActivityViewModel.cachedFileName)
	}
}
