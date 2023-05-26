//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift
import Combine
import OSLog

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
	public var lastExchangeDataRefreshDate: Date? = nil
	
	@Published var isFetchingData: Bool = false
	
	private var dispatchGroupBalances = DispatchGroup()
	private var currentlyRefreshingAccount: Account = Account(walletAddress: "")
	private static let cacheFilenameAccount = "balance-service-"
	private static let cacheFilenameExchangeData = "balance-service-exchangedata"
	private var bag_refreshAll = Set<AnyCancellable>()
	
	private static func accountCacheFilename(withAddress address: String?) -> String {
		return BalanceService.cacheFilenameAccount + (address ?? "")
	}
	
	public func loadCache(address: String?) {
		if let account = DiskService.read(type: Account.self, fromFileName: BalanceService.accountCacheFilename(withAddress: address)),
		   let exchangeData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			self.account = account
			self.exchangeData = exchangeData
			self.updateEstimatedTotal()
		}
	}
	
	public func refresh(addresses: [String], selectedAddress: String, completion: @escaping ((KukaiError?) -> Void)) {
		self.hasFetchedInitialData = false
		
		var futures: [Deferred<Future<Bool, KukaiError>>] = []
		for address in addresses {
			let isSelected = (selectedAddress == address)
			futures.append(fetchAllBalancesTokensAndPrices(forAddress: address, isSelectedAccount: isSelected, refreshType: .refreshEverything))
		}
		
		// Convert futures into sequential array
		guard let concatenatedPublishers = futures.concatenatePublishers() else {
			os_log("balanceService - unable to create concatenatedPublishers", type: .error)
			return
		}
		
		// Get the result of the concatenated publisher, whether it be successful payload, or error
		concatenatedPublishers
			.last()
			.convertToResult()
			.sink { concatenatedResult in
				guard let _ = try? concatenatedResult.get() else {
					let error = (try? concatenatedResult.getError()) ?? KukaiError.unknown()
					os_log("balanceService - refresh all - received error: %@", type: .debug, "\(error)")
					
					self.hasFetchedInitialData = true
					completion(error)
					return
				}
				
				self.hasFetchedInitialData = true
				completion(nil)
			}
			.store(in: &self.bag_refreshAll)
	}
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String, isSelectedAccount: Bool, refreshType: RefreshType) -> Deferred<Future<Bool, KukaiError>> {
		return Deferred {
			Future<Bool, KukaiError> { [weak self] promise in
				guard let self = self else {
					os_log("balanceService - fetch all future - can't find self", type: .error)
					promise(.failure(KukaiError.unknown()))
					return
				}
				
				self.fetchAllBalancesTokensAndPrices(forAddress: address, isSelectedAccount: isSelectedAccount, refreshType: refreshType) { error in
					if let e = error {
						promise(.failure(e))
					} else {
						promise(.success(true))
					}
				}
			}
		}
	}
	
	public func fetchAllBalancesTokensAndPrices(forAddress address: String, isSelectedAccount: Bool, refreshType: RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		
		isFetchingData = true
		
		var error: KukaiError? = nil
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		dispatchGroupBalances.enter()
		
		if refreshType == .useCache {
			let cachedAccount = DiskService.read(type: Account.self, fromFileName: BalanceService.accountCacheFilename(withAddress: address))
			
			self.currentlyRefreshingAccount = cachedAccount ?? Account(walletAddress: address, xtzBalance: .zero(), tokens: [], nfts: [], recentNFTs: [], liquidityTokens: [], delegate: nil, delegationLevel: nil)
			self.dispatchGroupBalances.leave()
			
			loadCachedExchangeDataIfNotLoaded()
			self.dispatchGroupBalances.leave()
			
		} else if refreshType == .refreshAccountOnly {
			
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
				guard let res = try? result.get() else {
					error = result.getFailure()
					self?.dispatchGroupBalances.leave()
					return
				}
				
				self?.currentlyRefreshingAccount = res
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
			
			loadCachedExchangeDataIfNotLoaded()
			self.dispatchGroupBalances.leave()
			
		} else if refreshType == .refreshEverything || (refreshType == .refreshEverythingIfStale && isEverythingStale()) {
			
			// Get all balance data from TzKT
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
				guard let res = try? result.get() else {
					error = result.getFailure()
					self?.dispatchGroupBalances.leave()
					return
				}
				
				self?.currentlyRefreshingAccount = res
				self?.dispatchGroupBalances.leave()
			}
			
			
			// Get all exchange rate data from DipDup
			fetchExchangeDataIfStale()
			
			
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
				// activityService is probably caching globally, need to update to per account
				// Check if there should be a .useCache override for stale data
				// cache ghostnet? by appending ghostnet to end of address
				// make sure OBJKT ghostnet queries aren't going out
				// update refresh if stale to track per account
				// trigger full refresh on imported account for first time
				
				
				// Make modifications, group, create sum totals on background
				self.updateEstimatedTotal()
				self.updateTokenStates(forAddress: address)
				self.orderGroupAndAliasNFTs {
					
					// Respond on main when everything done
					DispatchQueue.main.async {
						self.hasFetchedInitialData = true
						self.isFetchingData = false
						let _ = DiskService.write(encodable: self.currentlyRefreshingAccount, toFileName: BalanceService.accountCacheFilename(withAddress: address))
						
						if isSelectedAccount {
							self.account = self.currentlyRefreshingAccount
						}
						
						self.currentlyRefreshingAccount = Account(walletAddress: "")
						completion(nil)
					}
				}
			}
		}
	}
	
	private func fetchExchangeDataIfStale() {
		// If we've checked for excahnge data less than 10 minutes ago, ignore
		if (lastExchangeDataRefreshDate != nil && (lastExchangeDataRefreshDate ?? Date()).timeIntervalSince(Date()) < 60*10) {
			loadCachedExchangeDataIfNotLoaded()
			self.dispatchGroupBalances.leave()
			return
		}
		
		DependencyManager.shared.dipDupClient.getAllExchangesAndTokens { [weak self] result in
			guard let res = try? result.get() else {
				self?.dispatchGroupBalances.leave()
				return
			}
			
			self?.lastExchangeDataRefreshDate = Date()
			self?.exchangeData = res
			let _ = DiskService.write(encodable: res, toFileName: BalanceService.cacheFilenameExchangeData)
			self?.dispatchGroupBalances.leave()
		}
	}
	
	private func loadCachedExchangeDataIfNotLoaded() {
		if self.exchangeData.count == 0, let cachedData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			self.exchangeData = cachedData
		}
	}
	
	private func orderGroupAndAliasNFTs(completion: @escaping (() -> Void)) {
		var modifiedNFTs: [UUID: (token: Token, sortIndex: Int)] = [:]
		var unmodifiedNFTs: [Token] = []
		
		for token in self.currentlyRefreshingAccount.nfts {
			
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
			
			let newAccount = Account(walletAddress: self?.currentlyRefreshingAccount.walletAddress ?? "",
									 xtzBalance: self?.currentlyRefreshingAccount.xtzBalance ?? .zero(),
									 tokens: self?.currentlyRefreshingAccount.tokens ?? [],
									 nfts: newNFTs,
									 recentNFTs: self?.currentlyRefreshingAccount.recentNFTs ?? [],
									 liquidityTokens: self?.currentlyRefreshingAccount.liquidityTokens ?? [],
									 delegate: self?.currentlyRefreshingAccount.delegate,
									 delegationLevel: self?.currentlyRefreshingAccount.delegationLevel ?? 1)
			
			self?.currentlyRefreshingAccount = newAccount
			
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
		
		for token in self.currentlyRefreshingAccount.tokens {
			let dexRate = self.midPrice(forToken: token) // Use midPrice insread of dexRate to avoid calling multiple js calc library calls per token. MidPrice is close enough to give an estimate
			estimatedTotal += dexRate.xtzValue
			
			self.tokenValueAndRate[token.id] = dexRate
		}
		
		self.estimatedTotalXtz = self.currentlyRefreshingAccount.xtzBalance + estimatedTotal
	}
	
	func updateTokenStates(forAddress address: String, selectedAccount: Bool = false) {
		let hiddenBalances = TokenStateService.shared.hiddenBalances[address]
		let hiddenCollectibles = TokenStateService.shared.hiddenCollectibles[address]
		let favouriteBalances = TokenStateService.shared.favouriteBalances[address]
		let favouriteCollectibles = TokenStateService.shared.favouriteCollectibles[address]
		
		for token in (selectedAccount ? self.account.tokens : self.currentlyRefreshingAccount.tokens) {
			let tokenId = TokenStateService.shared.balanceId(from: token)
			token.isHidden = hiddenBalances?[tokenId] ?? false
			token.favouriteSortIndex = favouriteBalances?[tokenId]
		}
		
		for nftGroup in (selectedAccount ? self.account.nfts : self.currentlyRefreshingAccount.nfts) {
			
			var hiddenCount = 0
			for nftIndex in 0..<(nftGroup.nfts ?? []).count {
				
				if let nft = nftGroup.nfts?[nftIndex] {
					let nftId = TokenStateService.shared.nftId(from: nft)
					let isHidden = hiddenCollectibles?[nftId] ?? false
					
					hiddenCount += (isHidden ? 1 : 0)
					
					nftGroup.nfts?[nftIndex].isHidden = isHidden
					nftGroup.nfts?[nftIndex].favouriteSortIndex = favouriteCollectibles?[nftId]
				}
			}
			
			if hiddenCount == nftGroup.nfts?.count {
				nftGroup.isHidden = true
			}
		}
		
		if selectedAccount {
			let _ = DiskService.write(encodable: self.account, toFileName: BalanceService.accountCacheFilename(withAddress: address))
		}
	}
	
	func isEverythingStale() -> Bool {
		return (lastFullRefreshDate == nil || (lastFullRefreshDate ?? Date()).timeIntervalSince(Date()) > 120)
	}
	
	func midPrice(forToken token: Token) -> (xtzValue: XTZAmount, marketRate: Decimal) {
		guard let quipuOrFirst = exchangeDataForToken(token) else {
			return (xtzValue: .zero(), marketRate: 0)
		}
		
		let decimal = Decimal(string: quipuOrFirst.midPrice) ?? 0
		let amount = XTZAmount(fromNormalisedAmount: token.balance * decimal)
		
		return (xtzValue: amount, marketRate: decimal)
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
	
	func deleteAccountCachcedData(forAddress address: String) {
		let _ = DiskService.delete(fileName: BalanceService.accountCacheFilename(withAddress: address))
		account = Account(walletAddress: "")
		
		hasFetchedInitialData = false
	}
	
	func deleteAllCachedData() {
		let allAccounts = DiskService.allFileNamesWith(prefix: BalanceService.cacheFilenameAccount)
		let _ = DiskService.delete(fileNames: allAccounts)
		let _ = DiskService.delete(fileName: BalanceService.cacheFilenameExchangeData)
		
		hasFetchedInitialData = false
		
		account = Account(walletAddress: "")
		exchangeData = []
		
		tokenValueAndRate = [:]
		estimatedTotalXtz = XTZAmount.zero()
	}
	
	func token(forAddress address: String, andTokenId: Decimal? = nil) -> (token: Token, isNFT: Bool)? {
		for token in currentlyRefreshingAccount.tokens {
			if token.tokenContractAddress == address, (token.tokenId ?? (andTokenId ?? 0)) == (andTokenId ?? 0) {
				return (token: token, isNFT: false)
			}
		}
		
		for nftGroup in currentlyRefreshingAccount.nfts {
			if nftGroup.tokenContractAddress == address {
				return (token: nftGroup, isNFT: true)
			}
		}
		
		return nil
	}
}
