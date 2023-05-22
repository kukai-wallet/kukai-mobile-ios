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
	
	public enum RefreshType {
		case useCache
		case refreshIfCacheEmpty
		case forceRefresh
	}
	
	@Published var isFetchingData: Bool = false
	
	public var pendingTransactionGroups: [TzKTTransactionGroup] = []
	public var transactionGroups: [TzKTTransactionGroup] = []
	private static let pendingCachedFileName = "activity-service-transactions-pending"
	private static let cachedFileName = "activity-service-transactions"
	
	public func loadCache() {
		if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName) {
			self.transactionGroups = cachedGroups
		}
	}
	
	public func fetchTransactionGroups(forAddress address: String, refreshType: RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		
		isFetchingData = true
		
		if refreshType == .useCache,
			let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName),
			let pendingCachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingCachedFileName)  {
			
			self.transactionGroups = cachedGroups
			self.pendingTransactionGroups = pendingCachedGroups
			isFetchingData = false
			completion(nil)
			
		} else if refreshType == .refreshIfCacheEmpty {
			if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName), cachedGroups.count > 0 {
				self.transactionGroups = cachedGroups
				self.pendingTransactionGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.pendingCachedFileName) ?? []
				isFetchingData = false
				completion(nil)
				
			} else {
				remoteFetch(forAddress: address, completion: completion)
			}
			
		} else {
			remoteFetch(forAddress: address, completion: completion)
		}
	}
	
	private func remoteFetch(forAddress address: String, completion: @escaping ((KukaiError?) -> Void)) {
		DependencyManager.shared.tzktClient.fetchTransactions(forAddress: address, limit: 100) { [weak self] transactions in
			let groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: address)
			
			self?.transactionGroups = groups
			self?.checkAndUpdatePendingTransactions()
			let _ = DiskService.write(encodable: groups, toFileName: ActivityService.cachedFileName)
			
			self?.isFetchingData = false
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
			pendingTransactionGroups.insert(group, at: 0)
			DependencyManager.shared.accountBalancesDidUpdate = true
			return DiskService.write(encodable: pendingTransactionGroups, toFileName: ActivityService.pendingCachedFileName)
		}
		
		return false
	}
	
	public func checkAndUpdatePendingTransactions() {
		let now = Date()
		var indexesToRemove: [Int] = []
		
		for (index, pendingGroup) in pendingTransactionGroups.enumerated() {
			
			let timeSinceNow = pendingGroup.transactions.first?.date?.timeIntervalSince(now) ?? 0
			// If more than 2 hours has passed, it either made it in, or was dropped from mempool, either way its not pending anymore
			if timeSinceNow < -7200 {
				indexesToRemove.append(index)
				continue
			}
			
			for group in transactionGroups {
				if pendingGroup.hash == group.hash {
					indexesToRemove.append(index)
					break
				}
			}
		}
		
		if indexesToRemove.count > 0 {
			os_log("Removing %i pending transactions", indexesToRemove.count)
			pendingTransactionGroups.remove(atOffsets: IndexSet(indexesToRemove))
			let _ = DiskService.write(encodable: pendingTransactionGroups, toFileName: ActivityService.pendingCachedFileName)
			return
		}
		
		os_log("Pending transactions checked, none to remove")
	}
	
	public func deleteCache() {
		let _ = DiskService.delete(fileName: ActivityService.cachedFileName)
		let _ = DiskService.delete(fileName: ActivityService.pendingCachedFileName)
	}
}
