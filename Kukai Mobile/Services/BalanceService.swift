//
//  BalanceService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/06/2023.
//

import Foundation
import KukaiCoreSwift
import OSLog


public class BalanceService {
	
	// MARK: - Types
	
	public enum RefreshType {
		case useCache
		case useCacheIfNotStale
		case refreshAccountOnly
		case refreshEverything
	}
	
	public struct FetchRequestRecord: Hashable {
		let address: String
		let type: BalanceService.RefreshType
		
		public func hash(into hasher: inout Hasher) {
			hasher.combine(address)
			hasher.combine(type)
		}
		
		static public func ==(lhs: FetchRequestRecord, rhs: FetchRequestRecord) -> Bool {
			return lhs.address == rhs.address && lhs.type == rhs.type
		}
	}
	
	
	
	// MARK: - Current account state properties
	
	public var account = Account(walletAddress: "")
	
	
	
	// MARK: - Global state properties
	
	public var tokenValueAndRate: [String: (xtzValue: XTZAmount, marketRate: Decimal)] = [:]
	public var exchangeData: [DipDupExchangesAndTokens] = []
	public var lastExchangeDataRefreshDate: Date? = nil
	public var lastFullRefreshDates: [String: Date] = [:]
	public var estimatedTotalXtz: [String: XTZAmount] = [:]
	
	@Published public var addressesWaitingToBeRefreshed: [String] = []
	@Published public var addressRefreshed: String = ""
	
	private static let cacheFilenameAccount = "balance-service-"
	private static let cacheFilenameExchangeData = "balance-service-exchangedata"
	private static let cacheLastRefreshDates = "balance-service-refresh-dates"
	private static let cacheEstimatedTotals = "balance-service-estimated-total"
	
	
	
	// MARK: - Queue properties
	
	private var balanceRequestDispathGroup = DispatchGroup()
	private let balanceFetchQueue = DispatchQueue(label: "app.kukai.balance-service.fetch", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
	
	private var currentlyRefreshingAccount: Account = Account(walletAddress: "")
	private var needsCacheDateUpdate = false
	private var cacheLoadingInProgress = false
	private var currentFetchRequest: FetchRequestRecord? = nil
	private var pendingFetchRequests: [FetchRequestRecord] = []
	
	
	
	// MARK: - Init
	
	init() {
		lastFullRefreshDates = DiskService.read(type: [String: Date].self, fromFileName: BalanceService.cacheLastRefreshDates) ?? [:]
	}
	
	
	
	// MARK: - Queue Processing
	
	public func fetch(records: [FetchRequestRecord]) {
		let uniqueRecords = self.uniqueRecords(records: records)
		self.addressesWaitingToBeRefreshed.append(contentsOf: uniqueRecords.map({ $0.address }) )
		
		if currentFetchRequest == nil, let request = uniqueRecords.first {
			self.currentFetchRequest = request
			self.pendingFetchRequests.append(contentsOf: uniqueRecords.suffix(from: 1))
			self.processingCurrentRequest()
			
		} else {
			self.pendingFetchRequests.append(contentsOf: uniqueRecords)
		}
	}
	
	private func uniqueRecords(records: [FetchRequestRecord]) -> [FetchRequestRecord] {
		return NSOrderedSet(array: records).compactMap({ $0 as? FetchRequestRecord })
	}
	
	private func processingCurrentRequest() {
		guard let currentFetchRequest = currentFetchRequest else {
			return
		}
		
		balanceFetchQueue.async() { [weak self] in
			self?.fetchAllBalancesTokensAndPrices(forAddress: currentFetchRequest.address, refreshType: currentFetchRequest.type, completion: { error in
				
				DispatchQueue.main.async { [weak self] in
					// If an address on the list of to be refreshed, has had anything done at all, remove it from list
					if let index = self?.addressesWaitingToBeRefreshed.firstIndex(of: currentFetchRequest.address) {
						self?.addressesWaitingToBeRefreshed.remove(at: index)
						self?.addressRefreshed = currentFetchRequest.address
					}
					
					self?.processPendingRequests()
				}
			})
		}
	}
	
	private func processPendingRequests() {
		currentFetchRequest = nil
		
		if pendingFetchRequests.count > 0 {
			currentFetchRequest = pendingFetchRequests.first
			pendingFetchRequests.remove(at: 0)
			processingCurrentRequest()
		}
	}
	
	
	
	
	
	// MARK: - Cache
	
	public static func addressCacheKey(forAddress address: String) -> String {
		if DependencyManager.shared.currentNetworkType == .testnet {
			return address + "-ghostnet"
		}
		
		return address
	}
	
	private static func accountCacheFilename(withAddress address: String?) -> String {
		return BalanceService.cacheFilenameAccount + addressCacheKey(forAddress: address ?? "")
	}
	
	public func hasFetchedInitialData(forAddress address: String) -> Bool {
		let addressCacheKey = BalanceService.addressCacheKey(forAddress: address)
		return lastFullRefreshDates[addressCacheKey] != nil
	}
	
	public func isCacheLoadingInProgress() -> Bool {
		return cacheLoadingInProgress
	}
	
	public func loadCache(address: String?) {
		cacheLoadingInProgress = true
		loadCachedExchangeDataIfNotLoaded()
		loadEstimatedTotalsIfNotLoaded()
		
		if let account = DiskService.read(type: Account.self, fromFileName: BalanceService.accountCacheFilename(withAddress: address)) {
			
			DependencyManager.shared.coinGeckoService.loadLastTezosPrice()
			DependencyManager.shared.coinGeckoService.loadLastExchangeRates()
			DependencyManager.shared.activityService.loadCache(address: address)
			
			self.account = account
		}
		
		cacheLoadingInProgress = false
	}
	
	public func estimatedTotalXtz(forAddress: String) -> XTZAmount {
		let cacheKey = BalanceService.addressCacheKey(forAddress: forAddress)
		return self.estimatedTotalXtz[cacheKey] ?? .zero()
	}
	
	public func hasNotBeenFetched(forAddress address: String) -> Bool {
		let addressCacheKey = BalanceService.addressCacheKey(forAddress: address)
		return lastFullRefreshDates[addressCacheKey] == nil
	}
	
	public func hasBeenFetched(forAddress address: String) -> Bool {
		return !hasNotBeenFetched(forAddress: address)
	}
	
	public func isCacheStale(forAddress address: String) -> Bool {
		let addressCacheKey = BalanceService.addressCacheKey(forAddress: address)
		if let date = lastFullRefreshDates[addressCacheKey] {
			return Date().timeIntervalSince(date) > 540 // 5 minutes
		}
		
		return true
	}
	
	public func updateCacheDate(forAddress address: String) {
		let addressCacheKey = BalanceService.addressCacheKey(forAddress: address)
		lastFullRefreshDates[addressCacheKey] = Date()
		let _ = DiskService.write(encodable: lastFullRefreshDates, toFileName: BalanceService.cacheLastRefreshDates)
	}
	
	private func loadCachedExchangeDataIfNotLoaded() {
		if self.exchangeData.count == 0, let cachedData = DiskService.read(type: [DipDupExchangesAndTokens].self, fromFileName: BalanceService.cacheFilenameExchangeData) {
			self.exchangeData = cachedData
		}
	}
	
	private func loadEstimatedTotalsIfNotLoaded() {
		if self.estimatedTotalXtz.count == 0, let cachedData = DiskService.read(type: [String: XTZAmount].self, fromFileName: BalanceService.cacheEstimatedTotals) {
			self.estimatedTotalXtz = cachedData
		}
	}
	
	func deleteAccountCachcedData(forAddress address: String) {
		let _ = DiskService.delete(fileName: BalanceService.accountCacheFilename(withAddress: address))
		account = Account(walletAddress: "")
		
		let accountKey = BalanceService.addressCacheKey(forAddress: address)
		lastFullRefreshDates[accountKey] = nil
		let _ = DiskService.write(encodable: lastFullRefreshDates, toFileName: BalanceService.cacheLastRefreshDates)
	}
	
	func deleteAllCachedData() {
		let allAccounts = DiskService.allFileNamesWith(prefix: BalanceService.cacheFilenameAccount)
		let _ = DiskService.delete(fileNames: allAccounts)
		let _ = DiskService.delete(fileName: BalanceService.cacheFilenameExchangeData)
		let _ = DiskService.delete(fileName: BalanceService.cacheEstimatedTotals)
		let _ = DiskService.delete(fileName: BalanceService.cacheLastRefreshDates)
		
		lastFullRefreshDates = [:]
		lastExchangeDataRefreshDate = nil
		let _ = DiskService.write(encodable: lastFullRefreshDates, toFileName: BalanceService.cacheLastRefreshDates)
		
		account = Account(walletAddress: "")
		exchangeData = []
		
		tokenValueAndRate = [:]
		estimatedTotalXtz = [:]
	}
	
	
	
	
	// MARK: - Refresh
	
	private func fetchAllBalancesTokensAndPrices(forAddress address: String, refreshType: BalanceService.RefreshType, completion: @escaping ((KukaiError?) -> Void)) {
		self.currentlyRefreshingAccount = Account(walletAddress: address, xtzBalance: .zero(), tokens: [], nfts: [], recentNFTs: [], liquidityTokens: [], delegate: nil, delegationLevel: nil)
		
		var error: KukaiError? = nil
		balanceRequestDispathGroup.enter()
		balanceRequestDispathGroup.enter()
		balanceRequestDispathGroup.enter()
		balanceRequestDispathGroup.enter()
		balanceRequestDispathGroup.enter()
		balanceRequestDispathGroup.enter()
		
		if refreshType == .useCache || (refreshType == .useCacheIfNotStale && !isCacheStale(forAddress: address)) {
			let cachedAccount = DiskService.read(type: Account.self, fromFileName: BalanceService.accountCacheFilename(withAddress: address))
			
			self.currentlyRefreshingAccount = cachedAccount ?? Account(walletAddress: address, xtzBalance: .zero(), tokens: [], nfts: [], recentNFTs: [], liquidityTokens: [], delegate: nil, delegationLevel: nil)
			self.balanceRequestDispathGroup.leave()
			
			loadCachedExchangeDataIfNotLoaded()
			loadEstimatedTotalsIfNotLoaded()
			DependencyManager.shared.activityService.loadCache(address: address)
			self.balanceRequestDispathGroup.leave()
			
		} else if refreshType == .refreshAccountOnly {
			
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
				guard let res = try? result.get() else {
					error = result.getFailure()
					self?.balanceRequestDispathGroup.leave()
					return
				}
				
				self?.currentlyRefreshingAccount = res
				self?.balanceRequestDispathGroup.leave()
			}
			
			balanceRequestDispathGroup.enter()
			DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: address, completion: { [weak self] err in
				if let e = err {
					error = e
					self?.balanceRequestDispathGroup.leave()
					return
				}
				
				// Perform lookups on all unique destinations
				let allDestinations = DependencyManager.shared.activityService.transactionGroups.compactMap({ $0.transactions.first?.target?.address })
				let uniqueDestinations = Array(Set(allDestinations))
				let unresolvedDestinations = LookupService.shared.unresolvedDomains(addresses: uniqueDestinations)
				
				LookupService.shared.resolveAddresses(unresolvedDestinations) {
					DependencyManager.shared.activityService.loadCache(address: address)
					self?.balanceRequestDispathGroup.leave()
				}
			})
			
			loadCachedExchangeDataIfNotLoaded()
			loadEstimatedTotalsIfNotLoaded()
			DependencyManager.shared.activityService.loadCache(address: address)
			self.balanceRequestDispathGroup.leave()
			
		} else {
			// Get all balance data from TzKT
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
				guard let res = try? result.get() else {
					error = result.getFailure()
					self?.balanceRequestDispathGroup.leave()
					return
				}
				
				self?.currentlyRefreshingAccount = res
				self?.balanceRequestDispathGroup.leave()
			}
			
			
			// Get all exchange rate data from DipDup
			fetchExchangeDataIfStale()
			
			
			// Get latest transactions
			balanceRequestDispathGroup.enter()
			DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: address, completion: { [weak self] err in
				if let e = err {
					error = e
					self?.balanceRequestDispathGroup.leave()
					return
				}
				
				// Perform lookups on all unique destinations
				let allDestinations = DependencyManager.shared.activityService.transactionGroups.compactMap({ $0.transactions.first?.target?.address })
				let uniqueDestinations = Array(Set(allDestinations))
				let unresolvedDestinations = LookupService.shared.unresolvedDomains(addresses: uniqueDestinations)
				
				LookupService.shared.resolveAddresses(unresolvedDestinations) {
					DependencyManager.shared.activityService.loadCache(address: address)
					self?.needsCacheDateUpdate = true
					self?.balanceRequestDispathGroup.leave()
				}
			})
		}
		
		
		
		
		
		// Make sure we have the latest explore data
		DependencyManager.shared.exploreService.fetchExploreItems { [weak self] result in
			self?.balanceRequestDispathGroup.leave()
		}
		
		// Get latest Tezos USD price
		DependencyManager.shared.coinGeckoService.fetchTezosPrice { [weak self] result in
			guard let _ = try? result.get() else {
				error = result.getFailure()
				self?.balanceRequestDispathGroup.leave()
				return
			}
			
			self?.balanceRequestDispathGroup.leave()
		}
		
		// Get latest Exchange rates
		DependencyManager.shared.coinGeckoService.fetchExchangeRates { [weak self] result in
			guard let _ = try? result.get() else {
				error = result.getFailure()
				self?.balanceRequestDispathGroup.leave()
				return
			}
			
			self?.balanceRequestDispathGroup.leave()
		}
		
		// Check current chain information
		if DependencyManager.shared.tezosNodeClient.networkVersion == nil {
			DependencyManager.shared.tezosNodeClient.getNetworkInformation { success, e in
				if let err = error {
					error = err
				}
				
				self.balanceRequestDispathGroup.leave()
			}
		} else {
			self.balanceRequestDispathGroup.leave()
		}
		
		
		// When everything fetched, process data
		balanceRequestDispathGroup.notify(queue: .global(qos: .background)) { [weak self] in
			if let err = error {
				DispatchQueue.main.async { completion(err) }
				
			} else {
				guard let self = self else {
					DispatchQueue.main.async { completion(KukaiError.unknown()) }
					return
				}
				
				// Make modifications, group, create sum totals on background
				// TODO: consider performance improvement here. Only need to run these things if something has changed
				self.updateDexRatesAndEstimatedTotal() // TODO: if updated dex rates, exchange rates, or fiat price
				self.updateTokenStates(forAddress: address)
				self.orderGroupAndAliasNFTs { // TODO: only if we didn't load account cache, or explore items changed
					
					// If we haven't set Collections groupMode flag before, check it now that we have data to consider best option
					if !StorageService.hasUserDefaultKeyBeenSet(key: StorageService.settingsKeys.collectiblesGroupModeEnabled) {
						if self.currentlyRefreshingAccount.nfts.count > 2 && self.currentlyRefreshingAccount.nfts.map({ $0.nfts?.count ?? 0 }).reduce(0, +) > 10 {
							UserDefaults.standard.set(true, forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
						} else {
							UserDefaults.standard.set(false, forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
						}
					}
					
					let _ = DiskService.write(encodable: self.currentlyRefreshingAccount, toFileName: BalanceService.accountCacheFilename(withAddress: address))
					self.currentlyRefreshingAccount = Account(walletAddress: "")
					
					if self.needsCacheDateUpdate {
						self.updateCacheDate(forAddress: address)
						self.needsCacheDateUpdate = false
					}
					
					completion(nil)
				}
			}
		}
	}
	
	private func fetchExchangeDataIfStale() {
		// If we've checked for excahnge data less than 10 minutes ago, ignore
		if (lastExchangeDataRefreshDate != nil && (lastExchangeDataRefreshDate ?? Date()).timeIntervalSince(Date()) < 60*10) {
			loadCachedExchangeDataIfNotLoaded()
			self.balanceRequestDispathGroup.leave()
			return
		}
		
		DependencyManager.shared.dipDupClient.getAllExchangesAndTokens { [weak self] result in
			guard let res = try? result.get() else {
				self?.balanceRequestDispathGroup.leave()
				return
			}
			
			self?.lastExchangeDataRefreshDate = Date()
			self?.exchangeData = res
			let _ = DiskService.write(encodable: res, toFileName: BalanceService.cacheFilenameExchangeData)
			self?.balanceRequestDispathGroup.leave()
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
				let newToken = Token(name: exploreItem.name, symbol: "", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: exploreItem.thumbnailImageUrl, tokenContractAddress: token.tokenContractAddress, tokenId: 0, nfts: token.nfts ?? [], mintingTool: token.mintingTool)
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
		let addresses = self.currentlyRefreshingAccount.nfts.compactMap({ $0.tokenContractAddress })
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
	
	private func updateDexRatesAndEstimatedTotal() {
		var estimatedTotal: XTZAmount = .zero()
		
		for token in self.currentlyRefreshingAccount.tokens {
			let dexRate = self.midPrice(forToken: token) // Use midPrice insread of dexRate to avoid calling multiple js calc library calls per token. MidPrice is close enough to give an estimate
			self.tokenValueAndRate[token.id] = dexRate
			estimatedTotal += dexRate.xtzValue
		}
		
		let cacheKey = BalanceService.addressCacheKey(forAddress: self.currentlyRefreshingAccount.walletAddress)
		self.estimatedTotalXtz[cacheKey] = self.currentlyRefreshingAccount.xtzBalance + estimatedTotal
		
		let _ = DiskService.write(encodable: self.estimatedTotalXtz, toFileName: BalanceService.cacheEstimatedTotals)
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
		
		var recentNfts = (selectedAccount ? self.account.recentNFTs : self.currentlyRefreshingAccount.recentNFTs)
		for (index, nft) in recentNfts.enumerated() {
			let nftId = TokenStateService.shared.nftId(from: nft)
			let isHidden = hiddenCollectibles?[nftId] ?? false
			
			recentNfts[index].isHidden = isHidden
			recentNfts[index].favouriteSortIndex = favouriteCollectibles?[nftId]
		}
		
		if selectedAccount {
			self.account.recentNFTs = recentNfts
			let _ = DiskService.write(encodable: self.account, toFileName: BalanceService.accountCacheFilename(withAddress: address))
		} else {
			self.currentlyRefreshingAccount.recentNFTs = recentNfts
		}
	}
	
	
	
	
	
	// MARK: - Rates and prices
	
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
