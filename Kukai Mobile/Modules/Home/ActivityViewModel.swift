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

struct CellData: Hashable {
	let type: TzKTTransactionGroup.TransactionGroupType
	let title: String
	let subtitle: String
	let prefix: String
	let address: String
	let date: String
	let txId: Int
	let isSubItem: Bool
}

class ActivityViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var cellData: [CellData] = []
	private var expandedItems: [CellData] = []
	private var groups: [TzKTTransactionGroup] = []
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? CellData, obj.type != .exchange, obj.isSubItem == false, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityGenericCell", for: indexPath) as? ActivityGenericCell {
				cell.titleLabel.text = obj.title
				cell.prefixLabel.text = obj.prefix
				cell.addressLabel.text = obj.address
				cell.dateLabel.text = obj.date
				
				return cell
				
			} else if let obj = item as? CellData, obj.type == .exchange, obj.isSubItem == false, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityExchangeCell", for: indexPath) as? ActivityExchangeCell {
				cell.sentLabel.text = obj.title
				cell.receivedLabel.text = obj.subtitle
				cell.dateLabel.text = obj.date
				
				return cell
				
			} else if let obj = item as? CellData, obj.isSubItem == true, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivitySubItemCell", for: indexPath) as? ActivitySubItemCell {
				cell.titleLabel.text = obj.title
				
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
		
		guard let ds = dataSource, let walletAddress = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to find datasource")
			return
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections([0])
		
		
		
		DependencyManager.shared.tzktClient.fetchTransactions(forAddress: walletAddress) { [weak self] transactions in
			guard let self = self else {
				self?.state = .success(nil)
				return
			}
			
			self.groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: walletAddress)
			
			
			var cellData: [CellData] = []
			for group in self.groups {
				
				if group.groupType == .exchange {
					cellData.append(CellData(type: group.groupType,
											 title: "Swapped: \(group.primaryToken?.rpcAmount ?? "0") \(group.primaryToken?.target?.alias ?? "XTZ")",
											 subtitle: "For: \(group.secondaryToken?.rpcAmount ?? "0") \(group.secondaryToken?.target?.alias ?? "XTZ")",
											 prefix: "",
											 address: "",
											 date: "",
											 txId: group.transactions.first?.id ?? 0,
											 isSubItem: false))
					
				} else if group.groupType == .contractCall {
					cellData.append(CellData(type: group.groupType, title: "Called: \(group.entrypointCalled ?? "")", subtitle: "", prefix: "", address: "", date: "", txId: group.transactions.first?.id ?? 0, isSubItem: false))
					
				} else if group.groupType == .send {
					cellData.append(CellData(type: group.groupType,
											 title: "Sent: \(group.primaryToken?.rpcAmount ?? "0") \(group.primaryToken?.target?.alias ?? "XTZ")",
											 subtitle: "",
											 prefix: "To:",
											 address: group.transactions.first?.target?.address ?? "",
											 date: "",
											 txId: group.transactions.first?.id ?? 0,
											 isSubItem: false))
					
				} else if group.groupType == .receive {
					cellData.append(CellData(type: group.groupType,
											 title: "Received: \(group.primaryToken?.rpcAmount ?? "0") \(group.primaryToken?.target?.alias ?? "XTZ")",
											 subtitle: "",
											 prefix: "From:",
											 address: group.transactions.first?.sender.address ?? "",
											 date: "",
											 txId: group.transactions.first?.id ?? 0,
											 isSubItem: false))
					
				} else {
					cellData.append(CellData(type: group.groupType, title: "", subtitle: "", prefix: "", address: "", date: "", txId: group.transactions.first?.id ?? 0, isSubItem: false))
				}
			}
			
			self.cellData = cellData
			self.currentSnapshot.appendItems(cellData, toSection: 0)
			
			ds.apply(self.currentSnapshot, animatingDifferences: animate)
			self.state = .success(nil)
		}
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to find datasource")
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
		
		let group = self.groups[indexPath.row]
		let cellDataParent = self.cellData[indexPath.row]
		self.expandedItems = []
		
		for tx in group.transactions {
			self.expandedItems.append(CellData(type: .send, title: "\(tx.id)", subtitle: "", prefix: "", address: "", date: "", txId: tx.id, isSubItem: true))
		}
		
		currentSnapshot.insertItems(self.expandedItems, afterItem: cellDataParent)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityExchangeCell {
			cell.setClosed()
		}
		
		if let cell = tableView.cellForRow(at: indexPath) as? ActivityGenericCell {
			cell.setClosed()
		}
		
		currentSnapshot.deleteItems(self.expandedItems)
	}
}
