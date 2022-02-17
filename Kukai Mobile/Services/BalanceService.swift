//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class BalanceService {
	
	public var account = Account(walletAddress: "")
	public var exchangeData: [DipDupExchangesAndTokens] = []
	
	public var tokenValueAndRate: [String: (xtzValue: XTZAmount, marketRate: Decimal)] = [:]
	public var estimatedTotalXtz = XTZAmount.zero()
	
	
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
				guard let self = self else {
					completion(ErrorResponse.unknownError())
					return
				}
				
				var estiamtedTotal: XTZAmount = .zero()
				
				for token in self.account.tokens {
					let dexRate = self.dexRate(forToken: token)
					estiamtedTotal += dexRate.xtzValue
					
					self.tokenValueAndRate[token.id] = dexRate
				}
				
				self.estimatedTotalXtz = self.account.xtzBalance + estiamtedTotal
				
				completion(nil)
			}
		}
	}
	
	func dexRate(forToken token: Token) -> (xtzValue: XTZAmount, marketRate: Decimal) {
		guard let address = token.tokenContractAddress else {
			return (xtzValue: .zero(), marketRate: 0)
		}
		
		let data = exchangeData.first(where: { $0.address == address && $0.tokenId == (token.tokenId ?? 0) })
		let quipuOrFirst = data?.exchanges.first(where: { $0.name == .quipuswap }) ?? data?.exchanges.first
		
		guard let quipuOrFirst = quipuOrFirst else {
			return (xtzValue: .zero(), marketRate: 0)
		}
		
		let xtz = DexCalculationService.shared.tokenToXtzExpectedReturn(tokenToSell: token.balance, xtzPool: quipuOrFirst.xtzPoolAmount(), tokenPool: quipuOrFirst.tokenPoolAmount(), dex: quipuOrFirst.name) ?? .zero()
		let market = DexCalculationService.shared.tokenToXtzMarketRate(xtzPool: quipuOrFirst.xtzPoolAmount(), tokenPool: quipuOrFirst.tokenPoolAmount()) ?? 0
		
		return (xtzValue: xtz, marketRate: market)
	}
}
