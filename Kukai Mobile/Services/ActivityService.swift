//
//  ActivityService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2022.
//

import UIKit
import KukaiCoreSwift
import OSLog

public struct PendingBatchInfo {
	let type: TzKTTransaction.TransactionType
	let destination: TzKTAddress
	let xtzAmount: TokenAmount
	let parameters: [String: String]?
	let primaryToken: Token?
}

public class ActivityService {
	
	public var pendingTransactionGroups: [TzKTTransactionGroup] = []
	public var transactionGroups: [TzKTTransactionGroup] = []
	private static let pendingCachedFileName = "activity-service-pending-"
	private static let cachedFileName = "activity-service-"
	
	@Published public var addressesWithPendingOperation: [String] = []
	
	
	
	// MARK: - Init
	
	init() {
		
	}
	
	
	
	
	
	// MARK: - Cache
	
	private static func transactionsCacheFilename(withAddress address: String?) -> String {
		return ActivityService.cachedFileName + BalanceService.addressCacheKey(forAddress: address ?? "")
	}
	
	private static func pendingTransactionsCacheFilename(withAddress address: String?) -> String {
		return ActivityService.pendingCachedFileName + BalanceService.addressCacheKey(forAddress: address ?? "")
	}
	
	public func loadCache(address: String?) {
		Logger.app.info("ActivityService: loadCache \(address)")
		self.pendingTransactionGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
		
		if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.transactionsCacheFilename(withAddress: address)) {
			self.transactionGroups = cachedGroups
		}
	}
	
	func deleteAccountCachcedData(forAddress address: String) {
		let _ = DiskService.delete(fileName: ActivityService.transactionsCacheFilename(withAddress: address))
		let _ = DiskService.delete(fileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address))
	}
	
	public func deleteAllCachedData() {
		let allFiles1 = DiskService.allFileNamesWith(prefix: ActivityService.cachedFileName)
		let _ = DiskService.delete(fileNames: allFiles1)
		let allFiles2 = DiskService.allFileNamesWith(prefix: ActivityService.pendingCachedFileName)
		let _ = DiskService.delete(fileNames: allFiles2)
		
		self.transactionGroups = []
		self.pendingTransactionGroups = []
	}
	
	
	
	
	
	// MARK: - Transaction processing
	
	public func fetchTransactionGroups(forAddress address: String, completion: @escaping ((KukaiError?) -> Void)) {
		Logger.app.info("ActivityService: requesting transactions for \(address)")
		DependencyManager.shared.tzktClient.fetchTransactions(forAddress: address, limit: 100) { transactions in
			let groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: address)
			let _ = DiskService.write(encodable: groups, toFileName: ActivityService.transactionsCacheFilename(withAddress: address))
			
			Logger.app.info("ActivityService: requesting transactions for \(address) - complete")
			completion(nil)
		}
	}
	
	public func filterSendReceive(forToken: Token, count: Int) -> [TzKTTransactionGroup] {
		var transactions: [TzKTTransactionGroup] = []
		
		for group in self.transactionGroups {
			if group.transactions.count == 1,
				(group.groupType == .send || group.groupType == .receive),
			   (group.primaryToken?.tokenContractAddress == forToken.tokenContractAddress && group.primaryToken?.tokenId == forToken.tokenId && group.primaryToken?.symbol == forToken.symbol) {
				
				transactions.append(group)
				
				if transactions.count == count {
					break
				}
			}
		}
		
		return transactions
	}
	
	public func addPending(opHash: String, type: TzKTTransaction.TransactionType, counter: Decimal, fromWallet: WalletMetadata, destinationAddress: String, destinationAlias: String?, xtzAmount: TokenAmount, parameters: [String: String]?, primaryToken: Token?) -> Bool {
		Logger.app.info("ActivityService: add pending from \(fromWallet.address) with opHash: \(opHash)")
		let destination = TzKTAddress(alias: destinationAlias, address: destinationAddress)
		let previousId = pendingTransactionGroups.count == 0 ? (transactionGroups.first?.transactions.first?.id ?? 0) : (pendingTransactionGroups.first?.id ?? 0)
		var kind: String? = nil
		
		if parameters?["entrypoint"] == "stake" && destinationAddress == fromWallet.address {
			kind = "stake"
			
		} else if parameters?["entrypoint"] == "unstake" && destinationAddress == fromWallet.address {
			kind = "unstake"
			
		} else if parameters?["entrypoint"] == "finalize_unstake" && destinationAddress == fromWallet.address {
			kind = "finalize"
		}
		
		var transaction = TzKTTransaction.placeholder(withStatus: .unconfirmed, id: previousId + 1, opHash: opHash, type: type, counter: counter, fromWallet: fromWallet, destination: destination, xtzAmount: xtzAmount, parameters: parameters, primaryToken: primaryToken, baker: nil, kind: kind)
		transaction.processAdditionalData(withCurrentWalletAddress: fromWallet.address)
		
		if let group = TzKTTransactionGroup(withTransactions: [transaction], currentWalletAddress: fromWallet.address) {
			if fromWallet.address == DependencyManager.shared.selectedWalletAddress {
				pendingTransactionGroups.insert(group, at: 0)
				DependencyManager.shared.addressRefreshed = fromWallet.address
			}
			
			return DiskService.write(encodable: pendingTransactionGroups, toFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: fromWallet.address))
		}
		
		return false
	}
	
	public func addPendingBatch(opHash: String, counter: Decimal, fromWallet: WalletMetadata, batchInfo: [PendingBatchInfo]) -> Bool {
		Logger.app.info("ActivityService: add pending batch from \(fromWallet.address) with opHash: \(opHash)")
		var previousId = pendingTransactionGroups.count == 0 ? (transactionGroups.first?.transactions.first?.id ?? 0) : (pendingTransactionGroups.first?.id ?? 0)
		
		var transactions: [TzKTTransaction] = []
		for info in batchInfo {
			previousId += 1
			var temp = TzKTTransaction.placeholder(withStatus: .unconfirmed, id: previousId, opHash: opHash, type: info.type, counter: counter, fromWallet: fromWallet, destination: info.destination, xtzAmount: info.xtzAmount, parameters: info.parameters, primaryToken: info.primaryToken, baker: nil, kind: nil)
			temp.processAdditionalData(withCurrentWalletAddress: fromWallet.address)
			
			transactions.append(temp)
		}
		
		if let group = TzKTTransactionGroup(withTransactions: transactions, currentWalletAddress: fromWallet.address) {
			if fromWallet.address == DependencyManager.shared.selectedWalletAddress {
				pendingTransactionGroups.insert(group, at: 0)
				DependencyManager.shared.addressRefreshed = fromWallet.address
			}
			
			return DiskService.write(encodable: pendingTransactionGroups, toFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: fromWallet.address))
		}
		
		return false
	}
	
	public func addPending(opHash: String, type: TzKTTransaction.TransactionType, counter: Decimal, fromWallet: WalletMetadata, newDelegate: TzKTAddress?) -> Bool {
		Logger.app.info("ActivityService: add pending delegate from \(fromWallet.address) with opHash: \(opHash)")
		let previousId = pendingTransactionGroups.count == 0 ? (transactionGroups.first?.transactions.first?.id ?? 0) : (pendingTransactionGroups.first?.id ?? 0)
		let transaction = TzKTTransaction.placeholder(withStatus: .unconfirmed, id: previousId + 1, opHash: opHash, type: type, counter: counter, fromWallet: fromWallet, newDelegate: newDelegate)
		
		if let group = TzKTTransactionGroup(withTransactions: [transaction], currentWalletAddress: fromWallet.address) {
			if fromWallet.address == DependencyManager.shared.selectedWalletAddress {
				pendingTransactionGroups.insert(group, at: 0)
				DependencyManager.shared.addressRefreshed = fromWallet.address
			}
			
			return DiskService.write(encodable: pendingTransactionGroups, toFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: fromWallet.address))
		}
		
		return false
	}
	
	public func checkAndUpdatePendingTransactions(forAddress address: String, comparedToGroups: [TzKTTransactionGroup]) {
		Logger.app.info("ActivityService: checking pending for \(address)")
		let now = Date()
		let isRpcOnly = DependencyManager.shared.isRpcOnlyMode
		var indexesToRemove: [Int] = []
		
		var pending = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
		for (index, pendingGroup) in pending.enumerated() {
			
			let timeSinceNow = pendingGroup.transactions.first?.date?.timeIntervalSince(now) ?? 0
			
			// Experimental RPC only mode has no tzkt account change detection. A manual refresh will be triggered by a timer, if this happens, just assume tx was complete in order to stop animations
			if isRpcOnly {
				indexesToRemove.append(index)
				continue
			}
			
			// If more than 2 hours has passed, it either made it in, or was dropped from mempool, either way its not pending anymore
			if timeSinceNow < -7200 {
				indexesToRemove.append(index)
				continue
			}
			
			// During testing, we create fake pending operations to allow full simulated env
			if pendingGroup.transactions.first?.hash == "test" {
				indexesToRemove.append(index)
				continue
			}
			
			for group in comparedToGroups {
				if pendingGroup.hash == group.hash {
					
					// If we are removing a pending item, for something that has failed, display the window error for it
					if group.status == .failed || group.status == .backtracked {
						let fallbackErrorString = String(format: "error-generic-transaction-failure".localized(), address.truncateTezosAddress())
						UIApplication.shared.currentWindow?.displayError(title: "error".localized(), description: group.transactions.first?.errorString() ?? fallbackErrorString)
					}
					
					indexesToRemove.append(index)
					break
				}
			}
		}
		
		if indexesToRemove.count > 0 {
			pending.remove(atOffsets: IndexSet(indexesToRemove))
			self.pendingTransactionGroups = pending
			
			let _ = DiskService.write(encodable: pending, toFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address))
			if pending.count == 0 {
				self.updatePendingQueue(forAddress: address)
			}
			Logger.app.info("Pending transactions checked, removing index: \(indexesToRemove)")
			
		} else {
			self.updatePendingQueue(forAddress: address)
			Logger.app.info("Pending transactions checked, none to remove")
		}
	}
	
	public static func pendingOperationsFor(forAddress address: String) -> [TzKTTransactionGroup] {
		Logger.app.info("ActivityService: get pending operations for \(address)")
		return DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
	}
	
	public func addUniqueAddressToPendingOperation(address: String) {
		Logger.app.info("ActivityService: requesting to list address \(address), as containing pending")
		if !addressesWithPendingOperation.contains([address]) {
			Logger.app.info("ActivityService: adding address \(address), to pending")
			addressesWithPendingOperation.append(address)
		}
	}
	
	public func updatePendingQueue(forAddress address: String) {
		Logger.app.info("ActivityService: remove \(address), from pending queue")
		self.addressesWithPendingOperation.removeAll(where: { $0 == address })
	}
}
