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
		case refreshEverythingIfStale
	}
	
	public var hasFetchedInitialData = false
	public var currencyChanged = false
	
	public var account = Account(walletAddress: "")
	public var exchangeData: [DipDupExchangesAndTokens] = []
	
	public var tokenValueAndRate: [String: (xtzValue: XTZAmount, marketRate: Decimal)] = [:]
	public var estimatedTotalXtz = XTZAmount.zero()
	public var lastFullRefreshDate: Date? = nil
	
	@Published var isFetchingData: Bool = false
	
	private var dispatchGroupBalances = DispatchGroup()
	private static let cacheFilenameAccount = "balance-service-account"
	private static let cacheFilenameExchangeData = "balance-service-exchangedata"
	
	public func loadCache() {
		if let account = DiskService.read(type: Account.self, fromFileName: BalanceService.cacheFilenameAccount),
		   let exchangeData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			self.account = account
			self.exchangeData = exchangeData
			self.updateEstimatedTotal()
		}
	}
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String, refreshType: RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		
		isFetchingData = true
		
		var error: KukaiError? = nil
		dispatchGroupBalances.enter()
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
			
			dispatchGroupBalances.enter()
			DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: address, refreshType: .forceRefresh) { [weak self] err in
				if let e = err {
					error = e
					self?.dispatchGroupBalances.leave()
					return
				}
				
				self?.dispatchGroupBalances.leave()
			}
			
			self.exchangeData = exchangeData
			self.dispatchGroupBalances.leave()
			
		} else if refreshType == .refreshEverything || (refreshType == .refreshEverythingIfStale && isEverythingStale()) {
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
			
			// Get latest transactions
			dispatchGroupBalances.enter()
			DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: address, refreshType: .forceRefresh) { [weak self] err in
				if let e = err {
					error = e
					self?.dispatchGroupBalances.leave()
					return
				}
				
				self?.dispatchGroupBalances.leave()
			}
			
			lastFullRefreshDate = Date()
			
		} else {
			self.dispatchGroupBalances.leave()
			self.dispatchGroupBalances.leave()
		}
		
		// Make sure we have the latest explore data
		DependencyManager.shared.exploreService.fetchExploreItems { [weak self] result in
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
		dispatchGroupBalances.notify(queue: .global(qos: .background)) { [weak self] in
			if let err = error {
				DispatchQueue.main.async { completion(err) }
				
			} else {
				guard let self = self else {
					DispatchQueue.main.async { completion(KukaiError.unknown()) }
					return
				}
				
				// TODO:
				// need to re-write and implement `self.updateTokenStates()`
				// likely can drop all the calls to dex calculation service in here and just rely on the midPrice
				
				
				// Make modifications, group, create sum totals on background
				self.updateEstimatedTotal()
				//self.updateTokenStates() // Will write account to disk as well, no need to call again
				
				self.orderGroupAndAliasNFTs {
					let _ = DiskService.write(encodable: self.exchangeData, toFileName: BalanceService.cacheFilenameExchangeData)
					
					// Respond on main when everything done
					DispatchQueue.main.async {
						self.hasFetchedInitialData = true
						self.isFetchingData = false
						DependencyManager.shared.accountBalancesDidUpdate = true
						completion(nil)
					}
				}
			}
		}
	}
	
	private func orderGroupAndAliasNFTs(completion: @escaping (() -> Void)) {
		var modifiedNFTs: [UUID: (token: Token, sortIndex: Int)] = [:]
		var unmodifiedNFTs: [Token] = []
		
		for token in self.account.nfts {
			
			// Custom logic, search for teia links
			var address = token.tokenContractAddress ?? ""
			if address == "KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton" && token.mintingTool == "https://teia.art/mint" {
				address += "@teia"
			}
			
			// If there is no special logic for this token, add it in the order it came down in, and move on
			guard let exploreItem = DependencyManager.shared.exploreService.item(forAddress: address) else {
				unmodifiedNFTs.append(token)
				continue
			}
			
			
			// If there is special logic, we will create a new `Token` object and store it in `modifiedNFTs`
			// If the token already exists, we will append the nft contents of `Token` to the object and drop the token we got from tzkt
			if modifiedNFTs[exploreItem.primaryKey] != nil {
				modifiedNFTs[exploreItem.primaryKey]?.token.nfts?.append(contentsOf: token.nfts ?? [])
				
			} else {
				// TODO: need API updated in order to be able to get `thumbnailURL`
				let newToken = Token(name: exploreItem.name, symbol: "", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: exploreItem.address[0], tokenId: 0, nfts: token.nfts ?? [], mintingTool: token.mintingTool)
				modifiedNFTs[exploreItem.primaryKey] = (token: newToken, sortIndex: exploreItem.sortIndex)
			}
		}
		
		// Then we convert `modifiedNFTs` into an array and sort it based on sortIndex
		// Lastly writing it back to `self.account` with the `unmodifiedNFTs`
		var modifiedArray = Array(modifiedNFTs.values)
		modifiedArray = modifiedArray.sorted { lhs, rhs in
			lhs.sortIndex < rhs.sortIndex
		}
		
		
		// Ultimately we need data from OBJKT.com for the `unmodifiedNFTs`. Make a list of which ever ones don't exist, and bulk fetch them
		let addresses = unmodifiedNFTs.compactMap({ $0.tokenContractAddress })
		let unresolved = DependencyManager.shared.objktClient.unresolvedCollections(addresses: addresses)
		DependencyManager.shared.objktClient.resolveCollectionsAll(addresses: unresolved) { [weak self] _ in
			
			let newlyModified = self?.updateTokensWithObjktData(unmodifiedTokens: unmodifiedNFTs) ?? []
			
			var newNFTs = modifiedArray.map({ $0.token })
			newNFTs.append(contentsOf: newlyModified)
			
			let newAccount = Account(walletAddress: self?.account.walletAddress ?? "",
									 xtzBalance: self?.account.xtzBalance ?? .zero(),
									 tokens: self?.account.tokens ?? [],
									 nfts: newNFTs,
									 recentNFTs: self?.account.recentNFTs ?? [],
									 liquidityTokens: self?.account.liquidityTokens ?? [],
									 delegate: self?.account.delegate,
									 delegationLevel: self?.account.delegationLevel ?? 1)
			
			self?.account = newAccount
			
			completion()
		}
	}
	
	private func updateTokensWithObjktData(unmodifiedTokens: [Token]) -> [Token] {
		var newTokens: [Token] = []
		
		for token in unmodifiedTokens {
			if let address = token.tokenContractAddress, let objktData = DependencyManager.shared.objktClient.collections[address] {
				var url: URL? = nil
				if let logo = objktData.logo {
					url = MediaProxyService.url(fromUri: URL(string: logo), ofFormat: .icon)
				}
				
				let token = Token(name: objktData.name, symbol: "", tokenType: .nonfungible, faVersion: .fa2, balance: token.balance, thumbnailURL: url, tokenContractAddress: address, tokenId: token.tokenId, nfts: token.nfts, mintingTool: token.mintingTool)
				newTokens.append(token)
				
			} else {
				newTokens.append(token)
			}
		}
		
		return newTokens
	}
	
	private func updateEstimatedTotal() {
		var estimatedTotal: XTZAmount = .zero()
		
		for token in self.account.tokens {
			let dexRate = self.dexRate(forToken: token)
			estimatedTotal += dexRate.xtzValue
			
			self.tokenValueAndRate[token.id] = dexRate
		}
		
		self.estimatedTotalXtz = self.account.xtzBalance + estimatedTotal
	}
	
	func updateTokenStates() {
		
		for token in self.account.tokens {
			let favObj = TokenStateService.shared.isFavourite(token: token)
			token.isHidden = TokenStateService.shared.isHidden(token: token)
			token.isFavourite = favObj.isFavourite
			token.favouriteSortIndex = favObj.sortIndex
		}
		
		for nftGroup in self.account.nfts {
			
			var hiddenCount = 0
			for nftIndex in 0..<(nftGroup.nfts ?? []).count {
				
				if let nft = nftGroup.nfts?[nftIndex] {
					
					let isHidden = TokenStateService.shared.isHidden(nft: nft)
					hiddenCount += (isHidden ? 1 : 0)
					
					nftGroup.nfts?[nftIndex].isHidden = isHidden
					nftGroup.nfts?[nftIndex].isFavourite = TokenStateService.shared.isFavourite(nft: nft)
				}
			}
			
			if hiddenCount == nftGroup.nfts?.count {
				nftGroup.isHidden = true 
			}
		}
		
		let _ = DiskService.write(encodable: self.account, toFileName: BalanceService.cacheFilenameAccount)
	}
	
	func isEverythingStale() -> Bool {
		return (lastFullRefreshDate == nil || (lastFullRefreshDate ?? Date()).timeIntervalSince(Date()) > 120)
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
	
	func token(forAddress address: String, andTokenId: Decimal? = nil) -> (token: Token, isNFT: Bool)? {
		for token in account.tokens {
			if token.tokenContractAddress == address, (token.tokenId ?? (andTokenId ?? 0)) == (andTokenId ?? 0) {
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
