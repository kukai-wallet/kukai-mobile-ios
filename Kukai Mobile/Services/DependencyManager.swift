//
//  DependencyManager.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import Foundation
import Combine
import KukaiCoreSwift
import CustomAuth
import Sentry

struct WalletIndex {
	let parent: Int
	let child: Int?
}

class DependencyManager {
	
	static let shared = DependencyManager()
	
	static let defaultNodeURLs_mainnet = [URL(string: "https://mainnet.kukai.network")!, URL(string: "https://rpc.tzbeta.net")!, URL(string: "https://mainnet.smartpy.io")!]
	static let defaultTzktURL_mainnet = URL(string: "https://api.tzkt.io")!
	static let defaultBcdURL_mainnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_mainnet = URL(string: "https://api.tezos.domains/graphql")!
	static let defaultObjktURL_mainnet = URL(string: "https://data.objkt.com/v3/graphql")!
	
	static let defaultNodeURLs_testnet = [URL(string: "https://ghostnet.ecadinfra.com")!, URL(string: "https://rpc.ghostnet.tzboot.net")!, URL(string: "https://ghostnet.smartpy.io")!]
	static let defaultTzktURL_testnet = URL(string: "https://api.ghostnet.tzkt.io")!
	static let defaultBcdURL_testnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_testnet = URL(string: "https://ghostnet-api.tezos.domains/graphql")!
	static let defaultObjktURL_testnet = URL(string: "https://data.ghostnet.objkt.com/v3/graphql")!
	
	static let ghostnetFaucetLink = URL(string: "https://faucet.ghostnet.teztnets.com/")!
	
	
	// Kukai Core clients and properties
	var tezosClientConfig: TezosNodeClientConfig
	var tezosNodeClient: TezosNodeClient
	var tzktClient: TzKTClient
	var betterCallDevClient: BetterCallDevClient
	var torusAuthService: TorusAuthService
	var dipDupClient: DipDupClient
	var objktClient: ObjktClient
	var balanceService: BalanceService
	var activityService: ActivityService
	var coinGeckoService: CoinGeckoService
	var tezosDomainsClient: TezosDomainsClient
	var exploreService: ExploreService
	var discoverService: DiscoverService
	var appUpdateService: AppUpdateService
	
	var stubXtzPrice: Bool = false
	
	
	// Properties and helpers
	let sharedSession: URLSession
	var torusVerifiers: [TorusAuthProvider: SubverifierWrapper] = [:] {
		didSet {
			torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers)
		}
	}
	
	// Stored URL's and network info
	var currentNodeURLs: [URL] {
		set {
			let arrayOfStrings = newValue.map({ $0.absoluteString })
			UserDefaults.standard.setValue(arrayOfStrings, forKey: "app.kukai.mobile.node.url")
		}
		get {
			let arrayOfString = UserDefaults.standard.array(forKey: "app.kukai.mobile.node.url") as? [String] ?? []
			var urls: [URL] = []
			
			for str in arrayOfString {
				if let url = URL(string: str) {
					urls.append(url)
				}
			}
			
			if urls.count == 0 {
				urls = DependencyManager.defaultNodeURLs_mainnet
			}
			
			return urls
		}
	}
	
	var currentTzktURL: URL {
		set { UserDefaults.standard.setValue(newValue.absoluteString, forKey: "app.kukai.mobile.tzkt.url") }
		get { return URL(string: UserDefaults.standard.string(forKey: "app.kukai.mobile.tzkt.url") ?? "") ?? DependencyManager.defaultTzktURL_mainnet }
	}
	
	var currentBcdURL: URL {
		set { UserDefaults.standard.setValue(newValue.absoluteString, forKey: "app.kukai.mobile.bcd.url") }
		get { return URL(string: UserDefaults.standard.string(forKey: "app.kukai.mobile.bcd.url") ?? "") ?? DependencyManager.defaultBcdURL_mainnet }
	}
	
	var currentTezosDomainsURL: URL {
		set { UserDefaults.standard.setValue(newValue.absoluteString, forKey: "app.kukai.mobile.tezos-domains.url") }
		get { return URL(string: UserDefaults.standard.string(forKey: "app.kukai.mobile.tezos-domains.url") ?? "") ?? DependencyManager.defaultTezosDomainsURL_mainnet }
	}
	
	var currentObjktURL: URL {
		set { UserDefaults.standard.setValue(newValue.absoluteString, forKey: "app.kukai.mobile.objkt.url") }
		get { return URL(string: UserDefaults.standard.string(forKey: "app.kukai.mobile.objkt.url") ?? "") ?? DependencyManager.defaultObjktURL_mainnet }
	}
	
	var currentNetworkType: TezosNodeClientConfig.NetworkType {
		set { UserDefaults.standard.setValue(newValue.rawValue, forKey: "app.kukai.mobile.network.type") }
		get { return TezosNodeClientConfig.NetworkType(rawValue: UserDefaults.standard.string(forKey: "app.kukai.mobile.network.type") ?? "") ?? .mainnet }
	}
	
	
	
	// Wallet info / helpers
	
	var walletList: WalletMetadataList = WalletCacheService().readMetadataFromDiskAndDecrypt()
	
	private var _selectedWalletMetadata: WalletMetadata? = nil
	var selectedWalletMetadata: WalletMetadata? {
		set {
			_selectedWalletMetadata = newValue
			DependencyManager.shared.balanceService.setLoadingWallet()
			
			let encoded = try? JSONEncoder().encode(newValue)
			UserDefaults.standard.setValue(encoded, forKey: "app.kukai.mobile.selected.wallet")
			walletDidChange = true
		}
		get {
			if let cached = _selectedWalletMetadata {
				return cached
			}
			
			if let encoded = UserDefaults.standard.object(forKey: "app.kukai.mobile.selected.wallet") as? Data {
				let decoded = try? JSONDecoder().decode(WalletMetadata.self, from: encoded)
				_selectedWalletMetadata = decoded
				
				return decoded
			}
			
			return nil
		}
	}
	
	var selectedWalletAddress: String? {
		get {
			return selectedWalletMetadata?.address
		}
	}
	
	var selectedWallet: Wallet? {
		get {
			if let address = selectedWalletAddress {
				return WalletCacheService().fetchWallet(forAddress: address)
			}
			
			return nil
		}
	}
	
	// For use during WC2 flow where a user tentively selects an account, and we want to wait until its confirmed before switching
	var temporarySelectedWalletMetadata: WalletMetadata?
	var temporarySelectedWalletAddress: String? {
		get {
			return temporarySelectedWalletMetadata?.address
		}
	}
	
	
	// Combine publishers to serve as notifications across multiple screens
	// `@Published` can't be assigned to a computed property. To avoid loosing ability to wrap around UserDefaults
	// We create dummy published vars, where the actual value isn't relevant, we only care about triggering logic from these when a value is set
	@Published var networkDidChange: Bool = false
	@Published var walletDidChange: Bool = false
	@Published var addressLoaded: String = ""
	@Published var addressRefreshed: String = ""
	@Published var sideMenuOpen: Bool = false
	@Published var walletDeleted: Bool = false
	
	
	
	
	
	// MARK: - Init
	
	private init() {
		
		// Create shared URL session to be used for ALL networking requests throughout app
		let config = URLSessionConfiguration.default
		config.timeoutIntervalForRequest = 30
		config.timeoutIntervalForResource = 60
		config.urlCache = nil
		config.requestCachePolicy = .reloadIgnoringLocalCacheData
		sharedSession = URLSession(configuration: config)
		
		
		// To prevent stale cache issues, everytime DepenedencyManager is created, clear the entire cache
		URLCache.shared.removeAllCachedResponses()
		
		
		// Can't call self until all properties init'd, or made optional and nil'd. We need this setup logic accessible outside of the init,
		// To avoid code duplication, we setup the properties with default values and then call the shared func
		tezosClientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet)
		tezosNodeClient = TezosNodeClient(config: tezosClientConfig)
		betterCallDevClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		objktClient = ObjktClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, betterCallDevClient: betterCallDevClient, dipDupClient: dipDupClient)
		torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers)
		balanceService = BalanceService()
		activityService = ActivityService()
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		exploreService = ExploreService(networkService: tezosNodeClient.networkService, networkType: .mainnet)
		discoverService = DiscoverService(networkService: tezosNodeClient.networkService)
		appUpdateService = AppUpdateService(networkService: tezosNodeClient.networkService)
		
		coinGeckoService.stubPrice = self.stubXtzPrice
		
		updateKukaiCoreClients(supressUpdateNotification: true)
		
		
		// Central logging for all errors generated by KukaiCoreSwift
		ErrorHandlingService.shared.errorEventClosure = { err in
			if err.isTimeout() {
				SentrySDK.capture(message: "Timeout") { scope in
					scope.setLevel(.error)
					scope.setFingerprint(["client", "timeout"])
					scope.setExtras([
						"url": err.requestURL?.absoluteString ?? "-",
						"domain": err.subType?.domain ?? "-",
						"code": err.subType?.code ?? "-",
					])
				}
				
			}
		}
	}
	
	func setDefaultMainnetURLs(supressUpdateNotification: Bool = false) {
		currentNodeURLs = DependencyManager.defaultNodeURLs_mainnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_mainnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_mainnet
		currentObjktURL = DependencyManager.defaultObjktURL_mainnet
		currentNetworkType = .mainnet
		
		updateKukaiCoreClients(supressUpdateNotification: supressUpdateNotification)
	}
	
	func setDefaultTestnetURLs(supressUpdateNotification: Bool = false) {
		currentNodeURLs = DependencyManager.defaultNodeURLs_testnet
		currentTzktURL = DependencyManager.defaultTzktURL_testnet
		currentBcdURL = DependencyManager.defaultBcdURL_testnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_testnet
		currentObjktURL = DependencyManager.defaultObjktURL_testnet
		currentNetworkType = .testnet
		
		updateKukaiCoreClients(supressUpdateNotification: supressUpdateNotification)
	}
	
	func updateKukaiCoreClients(supressUpdateNotification: Bool = false) {
		tzktClient.stopListeningForAccountChanges()
		
		tezosClientConfig = TezosNodeClientConfig.configWithLocalForge(
			nodeURLs: currentNodeURLs,
			tzktURL: currentTzktURL,
			betterCallDevURL: currentBcdURL,
			tezosDomainsURL: currentTezosDomainsURL,
			objktApiURL: currentObjktURL,
			urlSession: sharedSession,
			networkType: currentNetworkType
		)
		
		tezosNodeClient = TezosNodeClient(config: tezosClientConfig)
		betterCallDevClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		objktClient = ObjktClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, betterCallDevClient: betterCallDevClient, dipDupClient: dipDupClient)
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		exploreService = ExploreService(networkService: tezosNodeClient.networkService, networkType: currentNetworkType)
		discoverService = DiscoverService(networkService: tezosNodeClient.networkService)
		appUpdateService = AppUpdateService(networkService: tezosNodeClient.networkService)
		
		coinGeckoService.stubPrice = self.stubXtzPrice
		
		if !supressUpdateNotification {
			networkDidChange = true
		}
	}
}
