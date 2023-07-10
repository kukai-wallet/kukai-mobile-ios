//
//  ActivityService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2022.
//

import Foundation
import KukaiCoreSwift
import OSLog

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
		self.pendingTransactionGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
		
		if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.transactionsCacheFilename(withAddress: address)) {
			self.transactionGroups = cachedGroups
		}
	}
	
	func deleteAccountCachcedData(forAddress address: String) {
		let _ = DiskService.delete(fileName: ActivityService.transactionsCacheFilename(withAddress: address))
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
		DependencyManager.shared.tzktClient.fetchTransactions(forAddress: address, limit: 100) { [weak self] transactions in
			let groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: address)
			
			self?.checkAndUpdatePendingTransactions(forAddress: address, comparedToGroups: groups)
			let _ = DiskService.write(encodable: groups, toFileName: ActivityService.transactionsCacheFilename(withAddress: address))
			
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
		let destination = TzKTAddress(alias: destinationAlias, address: destinationAddress)
		var transaction = TzKTTransaction.placeholder(withStatus: .unconfirmed, opHash: opHash, type: type, counter: counter, fromWallet: fromWallet, destination: destination, xtzAmount: xtzAmount, parameters: parameters, primaryToken: primaryToken)
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
	
	public func checkAndUpdatePendingTransactions(forAddress address: String, comparedToGroups: [TzKTTransactionGroup]) {
		let now = Date()
		var indexesToRemove: [Int] = []
		
		var pending = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
		for (index, pendingGroup) in pending.enumerated() {
			
			let timeSinceNow = pendingGroup.transactions.first?.date?.timeIntervalSince(now) ?? 0
			// If more than 2 hours has passed, it either made it in, or was dropped from mempool, either way its not pending anymore
			if timeSinceNow < -7200 {
				indexesToRemove.append(index)
				continue
			}
			
			for group in comparedToGroups {
				if pendingGroup.hash == group.hash {
					indexesToRemove.append(index)
					break
				}
			}
		}
		
		if indexesToRemove.count > 0 {
			pending.remove(atOffsets: IndexSet(indexesToRemove))
			let _ = DiskService.write(encodable: pending, toFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address))
			if pending.count == 0 {
				self.updatePendingQueue(forAddress: address)
			}
			os_log("Pending transactions checked, removing index: \(indexesToRemove)")
			
		} else {
			self.updatePendingQueue(forAddress: address)
			os_log("Pending transactions checked, none to remove")
		}
	}
	
	public static func pendingOperationsFor(forAddress address: String) -> [TzKTTransactionGroup] {
		return DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingTransactionsCacheFilename(withAddress: address)) ?? []
	}
	
	public func addUniqueAddressToPendingOperation(address: String) {
		if !addressesWithPendingOperation.contains([address]) {
			addressesWithPendingOperation.append(address)
		}
	}
	
	public func updatePendingQueue(forAddress address: String) {
		if let index = self.addressesWithPendingOperation.firstIndex(of: address) {
			self.addressesWithPendingOperation.remove(at: index)
		}
	}
}
