//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class BalanceService {
	
	static let shared = BalanceService()
	
	public var account: Account?
	public var exchangeData: [DipDupExchangesAndTokens] = []
	
	private init() {}
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String) {
		
		DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
			guard let res = try? result.get() else {
				//self?.state = .failure(result.getFailure(), "Unable to fetch data")
				return
			}
		}
		
		DependencyManager.shared.dipDupClient.getAllExchangesAndTokens { result in
			guard let res = try? result.get() else {
				//self?.state = .failure(result.getFailure(), "Unable to fetch data")
				return
			}
		}
		
	}
}
