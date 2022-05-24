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

struct WalletIndex {
	let parent: Int
	let child: Int?
}

class DependencyManager {
	
	static let shared = DependencyManager()
	
	static let defaultNodeURL_mainnet = URL(string: "https://mainnet.kukai.network")!
	static let defaultTzktURL_mainnet = URL(string: "https://api.tzkt.io")!
	static let defaultBcdURL_mainnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_mainnet = URL(string: "https://api.tezos.domains/graphql")!
	
	static let defaultNodeURL_testnet = URL(string: "https://hangzhounet.api.tez.ie")!
	static let defaultTzktURL_testnet = URL(string: "https://api.hangzhounet.tzkt.io")!
	static let defaultBcdURL_testnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_testnet = URL(string: "https://hangzhounet-api.tezos.domains/graphql")!
	
	
	// Kukai Core clients and properties
	var tezosClientConfig: TezosNodeClientConfig
	var tezosNodeClient: TezosNodeClient
	var tzktClient: TzKTClient
	var betterCallDevClient: BetterCallDevClient
	var torusAuthService: TorusAuthService
	var dipDupClient: DipDupClient
	var balanceService: BalanceService
	var coinGeckoService: CoinGeckoService
	var tezosDomainsClient: TezosDomainsClient
	
	
	// Properties and helpers
	let sharedSession: URLSession
	var torusVerifiers: [TorusAuthProvider: SubverifierWrapper] = [:] {
		didSet {
			torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers)
		}
	}
	
	// Stored URL's and network info
	var currentNodeURL: URL {
		set { UserDefaults.standard.setValue(newValue.absoluteString, forKey: "app.kukai.mobile.node.url") }
		get { return URL(string: UserDefaults.standard.string(forKey: "app.kukai.mobile.node.url") ?? "") ?? DependencyManager.defaultNodeURL_mainnet }
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
	
	var currentNetworkType: TezosNodeClientConfig.NetworkType {
		set { UserDefaults.standard.setValue(newValue.rawValue, forKey: "app.kukai.mobile.network.type") }
		get { return TezosNodeClientConfig.NetworkType(rawValue: UserDefaults.standard.string(forKey: "app.kukai.mobile.network.type") ?? "") ?? .mainnet }
	}
	
	var tezosChainName: TezosChainName {
		set { UserDefaults.standard.setValue(newValue.rawValue, forKey: "app.kukai.mobile.network.chainname") }
		get { return TezosChainName(rawValue: UserDefaults.standard.string(forKey: "app.kukai.mobile.network.chainname") ?? "") ?? .mainnet }
	}
	
	
	// Selected Wallet data
	var selectedWalletIndex: WalletIndex {
		set {
			UserDefaults.standard.setValue(newValue.parent, forKey: "app.kukai.mobile.selected.wallet.parent")
			UserDefaults.standard.setValue(newValue.child, forKey: "app.kukai.mobile.selected.wallet.child")
			walletDidChange = true
		}
		get {
			let parent = UserDefaults.standard.integer(forKey: "app.kukai.mobile.selected.wallet.parent")
			let child = UserDefaults.standard.object(forKey: "app.kukai.mobile.selected.wallet.child") as? Int
			return WalletIndex(parent: parent, child: child)
			
		}
	}
	
	var selectedWallet: Wallet? {
		get {
			if let wallets = WalletCacheService().fetchWallets() {
				
				if wallets.count == 0 {
					return nil
				}
				
				if selectedWalletIndex.parent >= wallets.count {
					selectedWalletIndex = WalletIndex(parent: wallets.count-1, child: nil)
				}
				
				let wallet = wallets[selectedWalletIndex.parent]
				
				if let childIndex = selectedWalletIndex.child, let hdWallet = wallet as? HDWallet {
					return hdWallet.childWallets[childIndex]
				} else {
					return wallet
				}
			}
			
			return nil
		}
	}
	
	
	// Combine publishers to serve as notifications across multiple screens
	// `@Published` can't be assigned to a computed property. To avoid loosing ability to wrap around UserDefaults
	// We create dummy published vars, where the actual value isn't relevant, we only care about triggering logic from these when a value is set
	@Published var networkDidChange: Bool = false
	@Published var walletDidChange: Bool = false
	@Published var accountBalancesDidUpdate: Bool = false
	
	
	
	
	
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
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, betterCallDevClient: betterCallDevClient)
		torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		balanceService = BalanceService()
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		
		updateKukaiCoreClients()
	}
	
	func setDefaultMainnetURLs(supressUpdateNotification: Bool = false) {
		currentNodeURL = DependencyManager.defaultNodeURL_mainnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_mainnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_mainnet
		tezosChainName = .mainnet
		currentNetworkType = .mainnet
		
		updateKukaiCoreClients(supressUpdateNotification: supressUpdateNotification)
	}
	
	func setDefaultTestnetURLs(supressUpdateNotification: Bool = false) {
		currentNodeURL = DependencyManager.defaultNodeURL_testnet
		currentTzktURL = DependencyManager.defaultTzktURL_testnet
		currentBcdURL = DependencyManager.defaultBcdURL_testnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_testnet
		tezosChainName = .hangzhounet
		currentNetworkType = .testnet
		
		updateKukaiCoreClients(supressUpdateNotification: supressUpdateNotification)
	}
	
	func updateKukaiCoreClients(supressUpdateNotification: Bool = false) {
		tezosClientConfig = TezosNodeClientConfig.configWithLocalForge(
			primaryNodeURL: currentNodeURL,
			tezosChainName: tezosChainName,
			tzktURL: currentTzktURL,
			betterCallDevURL: currentBcdURL,
			tezosDomainsURL: currentTezosDomainsURL,
			urlSession: sharedSession,
			networkType: currentNetworkType
		)
		
		tezosNodeClient = TezosNodeClient(config: tezosClientConfig)
		betterCallDevClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, betterCallDevClient: betterCallDevClient)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		balanceService = BalanceService()
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		
		if !supressUpdateNotification {
			networkDidChange = true
		}
	}
}
