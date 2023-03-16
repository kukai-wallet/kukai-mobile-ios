//
//  ActivityService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2022.
//

import Foundation
import KukaiCoreSwift

public class ActivityService {
	
	public enum RefreshType {
		case useCache
		case refreshIfCacheEmpty
		case forceRefresh
	}
	
	@Published var isFetchingData: Bool = false
	
	public var transactionGroups: [TzKTTransactionGroup] = []
	private static let cachedFileName = "activity-service-transactions"
	
	public func loadCache() {
		if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName) {
			self.transactionGroups = cachedGroups
		}
	}
	
	public func fetchTransactionGroups(forAddress address: String, refreshType: RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		
		isFetchingData = true
		
		if refreshType == .useCache, let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName) {
			self.transactionGroups = cachedGroups
			isFetchingData = false
			completion(nil)
			
		} else if refreshType == .refreshIfCacheEmpty {
			if let cachedGroups = DiskService.read(type: [TzKTTransactionGroup].self, fromFileName: ActivityService.cachedFileName), cachedGroups.count > 0 {
				self.transactionGroups = cachedGroups
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
	
	public func deleteCache() {
		let _ = DiskService.delete(fileName: ActivityService.cachedFileName)
	}
}
