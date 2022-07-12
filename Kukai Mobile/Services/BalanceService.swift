//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class BalanceService {
	
	public enum RefreshType {
		case useCache
		case refreshAccountOnly
		case refreshEverything
	}
	
	public var hasFetchedInitialData = false
	public var currencyChanged = false
	
	public var account = Account(walletAddress: "")
	public var exchangeData: [DipDupExchangesAndTokens] = []
	
	public var tokenValueAndRate: [String: (xtzValue: XTZAmount, marketRate: Decimal)] = [:]
	public var estimatedTotalXtz = XTZAmount.zero()
	
	@Published var isFetchingData: Bool = false
	
	private var dispatchGroupBalances = DispatchGroup()
	private static let cacheFilenameAccount = "balance-service-account"
	private static let cacheFilenameExchangeData = "balance-service-exchangedata"
	
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String, refreshType: RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		
		isFetchingData = true
		
		var error: KukaiError? = nil
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		
		if refreshType == .useCache,
		   let account = DiskService.read(type: Account.self, fromFileName: BalanceService.cacheFilenameAccount),
		   let exchangeData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			
			self.account = account
			self.dispatchGroupBalances.leave()
			
			self.exchangeData = exchangeData
			self.dispatchGroupBalances.leave()
			
		} else if refreshType == .refreshAccountOnly,
				  let exchangeData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
				guard let res = try? result.get() else {
					error = result.getFailure()
					self?.dispatchGroupBalances.leave()
					return
				}
				
				self?.account = res
				self?.dispatchGroupBalances.leave()
			}
			
			self.exchangeData = exchangeData
			self.dispatchGroupBalances.leave()
			
		} else {
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
		
		// Check current chain information
		if DependencyManager.shared.tezosNodeClient.networkVersion == nil {
			DependencyManager.shared.tezosNodeClient.getNetworkInformation { success, e in
				if let err = error {
					error = err
				}
				
				self.dispatchGroupBalances.leave()
			}
		} else {
			self.dispatchGroupBalances.leave()
		}
		
		
		
		// When everything fetched, process data
		dispatchGroupBalances.notify(queue: .main) { [weak self] in
			if let err = error {
				completion(err)
				
			} else {
				guard let self = self else {
					completion(KukaiError.unknown())
					return
				}
				
				var estiamtedTotal: XTZAmount = .zero()
				
				for token in self.account.tokens {
					let dexRate = self.dexRate(forToken: token)
					estiamtedTotal += dexRate.xtzValue
					
					self.tokenValueAndRate[token.id] = dexRate
				}
				
				self.estimatedTotalXtz = self.account.xtzBalance + estiamtedTotal
				self.hasFetchedInitialData = true
				self.isFetchingData = false
				DependencyManager.shared.accountBalancesDidUpdate = true
				
				let _ = DiskService.write(encodable: self.account, toFileName: BalanceService.cacheFilenameAccount)
				let _ = DiskService.write(encodable: self.exchangeData, toFileName: BalanceService.cacheFilenameExchangeData)
				
				completion(nil)
			}
		}
	}
	
	func dexRate(forToken token: Token) -> (xtzValue: XTZAmount, marketRate: Decimal) {
		guard let quipuOrFirst = exchangeDataForToken(token) else {
			return (xtzValue: .zero(), marketRate: 0)
		}
		
		let xtz = xtzExchange(forToken: token, ofAmount: token.balance, withExchangeData: quipuOrFirst)
		let market = DexCalculationService.shared.tokenToXtzMarketRate(xtzPool: quipuOrFirst.xtzPoolAmount(), tokenPool: quipuOrFirst.tokenPoolAmount()) ?? 0
		
		return (xtzValue: xtz, marketRate: market)
	}
	
	func exchangeDataForToken(_ token: Token) -> DipDupExchange? {
		let data = exchangeData.first(where: { $0.address == token.tokenContractAddress && $0.tokenId == (token.tokenId ?? 0) })
		return data?.exchanges.first(where: { $0.name == .quipuswap }) ?? data?.exchanges.first
	}
	
	func xtzExchange(forToken: Token, ofAmount amount: TokenAmount, withExchangeData: DipDupExchange) -> XTZAmount {
		return DexCalculationService.shared.tokenToXtzExpectedReturn(tokenToSell: amount, xtzPool: withExchangeData.xtzPoolAmount(), tokenPool: withExchangeData.tokenPoolAmount(), dex: withExchangeData.name) ?? .zero()
	}
	
	func fiatAmount(forToken: Token, ofAmount: TokenAmount) -> Decimal {
		if forToken.isXTZ() {
			return ofAmount * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			
		} else {
			guard let exchangeData = exchangeDataForToken(forToken) else {
				return 0
			}
			
			let xtzExchange = xtzExchange(forToken: forToken, ofAmount: ofAmount, withExchangeData: exchangeData)
			return xtzExchange * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
		}
	}
	
	func fiatAmountDisplayString(forToken: Token, ofAmount: TokenAmount) -> String {
		let amount = fiatAmount(forToken: forToken, ofAmount: ofAmount)
		return DependencyManager.shared.coinGeckoService.format(decimal: amount, numberStyle: .currency, maximumFractionDigits: 2)
	}
	
	func deleteAccountCachcedData() {
		let _ = DiskService.delete(fileName: BalanceService.cacheFilenameAccount)
		account = Account(walletAddress: "")
		
		hasFetchedInitialData = false
	}
	
	func deleteAllCachedData() {
		let _ = DiskService.delete(fileName: BalanceService.cacheFilenameAccount)
		let _ = DiskService.delete(fileName: BalanceService.cacheFilenameExchangeData)
		
		hasFetchedInitialData = false
		
		account = Account(walletAddress: "")
		exchangeData = []
		
		tokenValueAndRate = [:]
		estimatedTotalXtz = XTZAmount.zero()
	}
	
	func token(forAddress address: String) -> (token: Token, isNFT: Bool)? {
		for token in account.tokens {
			if token.tokenContractAddress == address {
				return (token: token, isNFT: false)
			}
		}
		
		for nftGroup in account.nfts {
			if nftGroup.tokenContractAddress == address {
				return (token: nftGroup, isNFT: true)
			}
		}
		
		return nil
	}
}
