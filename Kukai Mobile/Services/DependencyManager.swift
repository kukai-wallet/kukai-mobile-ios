//
//  DependencyManager.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import Foundation
import KukaiCoreSwift

class DependencyManager {
	
	static let shared = DependencyManager()
	
	static let defaultNodeURL_mainnet = URL(string: "https://api.tez.ie/rpc/mainnet")!
	static let defaultTzktURL_mainnet = URL(string: "https://api.tzkt.io")!
	static let defaultBcdURL_mainnet = URL(string: "https://api.better-call.dev")!
	
	static let defaultNodeURL_testnet = URL(string: "https://api.tez.ie/rpc/florencenet")!
	static let defaultTzktURL_testnet = URL(string: "https://api.florencenet.tzkt.io")!
	static let defaultBcdURL_testnet = URL(string: "https://api.better-call.dev")!
	
	
	// Kukai Core clients and properties
	var tezosClientConfig: TezosNodeClientConfig
	var tezosNodeClient: TezosNodeClient
	var tzktClient: TzKTClient
	var betterCallDevClient: BetterCallDevClient
	var torusAuthService: TorusAuthService
	var tezosChainName: TezosChainName
	
	
	// Properties and helpers
	let sharedSession: URLSession
	
	
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
	
	var currentNetworkType: TezosNodeClientConfig.NetworkType {
		set { UserDefaults.standard.setValue(newValue.rawValue, forKey: "app.kukai.mobile.network.type") }
		get { return TezosNodeClientConfig.NetworkType(rawValue: UserDefaults.standard.string(forKey: "app.kukai.mobile.network.type") ?? "") ?? .mainnet }
	}
	
	
	// Selected Wallet data
	var selectedWalletIndex: Int {
		set { UserDefaults.standard.setValue(newValue, forKey: "app.kukai.mobile.selected.wallet") }
		get { return UserDefaults.standard.integer(forKey: "app.kukai.mobile.selected.wallet") }
	}
	
	var selectedWallet: Wallet? {
		get {
			if let wallets = WalletCacheService().fetchWallets() {
				return wallets[selectedWalletIndex]
			}
			
			return nil
		}
	}
	
	
	
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
		torusAuthService = TorusAuthService(networkType: tezosClientConfig.networkType, networkService: tezosNodeClient.networkService, nativeRedirectURL: "", googleRedirectURL: "", browserRedirectURL: "")
		tezosChainName = .florencenet
		
		
		updateKukaiCoreClients()
	}
	
	func setDefaultMainnetURLs() {
		currentNodeURL = DependencyManager.defaultNodeURL_mainnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_mainnet
		tezosChainName = .mainnet
		currentNetworkType = .mainnet
		
		updateKukaiCoreClients()
	}
	
	func setDefaultTestnetURLs() {
		currentNodeURL = DependencyManager.defaultNodeURL_testnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_testnet
		tezosChainName = .florencenet
		currentNetworkType = .testnet
		
		updateKukaiCoreClients()
	}
	
	func updateKukaiCoreClients() {
		tezosClientConfig = TezosNodeClientConfig.configWithLocalForge(
			primaryNodeURL: currentNodeURL,
			tezosChainName: tezosChainName,
			tzktURL: currentTzktURL,
			betterCallDevURL: currentBcdURL,
			urlSession: sharedSession,
			networkType: currentNetworkType
		)
		
		tezosNodeClient = TezosNodeClient(config: tezosClientConfig)
		betterCallDevClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, betterCallDevClient: betterCallDevClient)
		
		torusAuthService = TorusAuthService(
			networkType: tezosClientConfig.networkType,
			networkService: tezosNodeClient.networkService,
			nativeRedirectURL: "tdsdk://tdsdk/oauthCallback",
			googleRedirectURL: "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
			browserRedirectURL: "https://scripts.toruswallet.io/redirect.html"
		)
	}
}
