//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class BalanceService {
	
	public var account: Account?
	public var exchangeData: [DipDupExchangesAndTokens] = []
	
	public var tokenValueAndRate: [String: (xtzValue: Decimal, marketRate: Decimal)] = [:]
	
	
	private var dispatchGroupBalances = DispatchGroup()
	
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String, completion: @escaping ((ErrorResponse?) -> Void)) {
		
		var error: ErrorResponse? = nil
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		
		// Get all balance data from TzKT
		DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupBalances.leave()
				return
			}
			
			self?.account = res
			self?.dispatchGroupBalances.leave()
		}
		
		// Get all exchange rate data from DipDup
		DependencyManager.shared.dipDupClient.getAllExchangesAndTokens { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupBalances.leave()
				return
			}
			
			self?.exchangeData = res
			self?.dispatchGroupBalances.leave()
		}
		
		// Get latest Tezos USD price
		DependencyManager.shared.coinGeckoService.fetchTezosPrice { [weak self] result in
			guard let _ = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupBalances.leave()
				return
			}
			
			self?.dispatchGroupBalances.leave()
		}
		
		// Get latest Exchange rates
		DependencyManager.shared.coinGeckoService.fetchExchangeRates { [weak self] result in
			guard let _ = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupBalances.leave()
				return
			}
			
			self?.dispatchGroupBalances.leave()
		}
		
		// When everything fetched, process data
		dispatchGroupBalances.notify(queue: .main) { [weak self] in
			if let err = error {
				completion(err)
				
			} else {
				for token in self?.account?.tokens ?? [] {
					let marketRate = self?.dexRate(forToken: token) ?? 0
					let totalXTZValue = token.balance * marketRate
					
					self?.tokenValueAndRate[token.id] = (xtzValue: totalXTZValue, marketRate: marketRate)
				}
				
				completion(nil)
			}
		}
	}
	
	func dexRate(forToken token: Token) -> Decimal {
		guard let address = token.tokenContractAddress else {
			return 0
		}
		
		let data = exchangeData.first(where: { $0.address == address && $0.tokenId == (token.tokenId ?? 0) })
		let quipuOrFirst = data?.exchanges.first(where: { $0.name == .quipuswap }) ?? data?.exchanges.first
		
		guard let quipuOrFirst = quipuOrFirst else {
			return 0
		}

		return DexCalculationService.shared.xtzToTokenMarketRate(xtzPool: quipuOrFirst.xtzPoolAmount(), tokenPool: quipuOrFirst.tokenPoolAmount()) ?? 0
	}
}
