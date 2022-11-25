//
//  ActivityService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2022.
//


/*
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
	
	}
*/

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
		DependencyManager.shared.tzktClient.fetchTransactions(forAddress: address) { [weak self] transactions in
			let groups = DependencyManager.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: address)
			
			self?.transactionGroups = groups
			let _ = DiskService.write(encodable: groups, toFileName: ActivityService.cachedFileName)
			
			self?.isFetchingData = false
			completion(nil)
		}
	}
	
	public func filterSendReceive(forToken: Token) -> [TzKTTransactionGroup] {
		var transactions: [TzKTTransactionGroup] = []
		
		for group in self.transactionGroups {
			if group.transactions.count == 1,
				(group.groupType == .send || group.groupType == .receive),
			   (group.primaryToken?.token.tokenContractAddress == forToken.tokenContractAddress && group.primaryToken?.token.tokenId == forToken.tokenId && group.primaryToken?.token.symbol == forToken.symbol) {
				
				transactions.append(group)
			}
		}
		
		return transactions
	}
}
