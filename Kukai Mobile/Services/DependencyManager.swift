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

class DependencyManager {
	
	static let shared = DependencyManager()
	
	static let defaultNodeURL_mainnet = URL(string: "https://api.tez.ie/rpc/mainnet")!
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
	var selectedWalletIndex: Int {
		set {
			UserDefaults.standard.setValue(newValue, forKey: "app.kukai.mobile.selected.wallet")
			walletDidChange = true
		}
		get { return UserDefaults.standard.integer(forKey: "app.kukai.mobile.selected.wallet") }
	}
	
	var selectedWallet: Wallet? {
		get {
			if let wallets = WalletCacheService().fetchWallets() {
				
				if wallets.count == 0 {
					return nil
				}
				
				if selectedWalletIndex >= wallets.count {
					selectedWalletIndex = wallets.count-1
				}
				
				return wallets[selectedWalletIndex]
			}
			
			return nil
		}
	}
	
	var currentAccount: Account? = nil
	
	
	// Combine publishers to serve as notifications across multiple screens
	// `@Published` can't be assigned to a computed property. To avoid loosing ability to wrap around UserDefaults
	// We create dummy published vars, where the actual value isn't relevant, we only care about triggering logic from these when a value is set
	@Published var networkDidChange: Bool = false
	@Published var walletDidChange: Bool = false
	
	
	// Torus / Social data
	private let testnetVerifiers: [TorusAuthProvider: SubverifierWrapper] = [
		.apple: SubverifierWrapper(aggregateVerifierName: "kukai-apple-testnet", subverifier: SubVerifierDetails(
			loginType: .installed,
			loginProvider: .apple,
			clientId: "",
			verifierName: "kukai-apple-dev", // TODO: change back
			redirectURL: "tdsdk://tdsdk/oauthCallback"
		)),
		.twitter: SubverifierWrapper(aggregateVerifierName: nil, subverifier: SubVerifierDetails(
			loginType: .web,
			loginProvider: .twitter,
			clientId: "A7H8kkcmyFRlusJQ9dZiqBLraG2yWIsO",
			verifierName: "torus-auth0-twitter-lrc",
			redirectURL: "tdsdk://tdsdk/oauthCallback",
			jwtParams: ["domain": "torus-test.auth0.com"]
		)),
		.google: SubverifierWrapper(aggregateVerifierName: "kukai-google", subverifier: SubVerifierDetails(
			loginType: .installed,
			loginProvider: .google,
			clientId: "952872982551-os146b77tatd0o36q9l195s3s674odv8.apps.googleusercontent.com",
			verifierName: "mobile-kukai-dev",
			redirectURL: "com.googleusercontent.apps.952872982551-os146b77tatd0o36q9l195s3s674odv8:/oauthredirect"
		)),
		.reddit: SubverifierWrapper(aggregateVerifierName: nil, subverifier: SubVerifierDetails(
			loginType: .web,
			loginProvider: .reddit,
			clientId: "rXIp6g2y3h1wqg",
			verifierName: "reddit-shubs",
			redirectURL: "tdsdk://tdsdk/oauthCallback"
		)),
		.facebook: SubverifierWrapper(aggregateVerifierName: nil, subverifier: SubVerifierDetails(
			loginType: .web,
			loginProvider: .facebook,
			clientId: "659561074900150",
			verifierName: "facebook-shubs",
			redirectURL: "tdsdk://tdsdk/oauthCallback",
			browserRedirectURL: "https://scripts.toruswallet.io/redirect.html"
		))
	]
	
	
	
	
	
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
		torusAuthService = TorusAuthService(networkType: tezosClientConfig.networkType, networkService: tezosNodeClient.networkService, testnetVerifiers: testnetVerifiers, mainnetVerifiers: testnetVerifiers)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		balanceService = BalanceService()
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		
		updateKukaiCoreClients()
	}
	
	func setDefaultMainnetURLs() {
		currentNodeURL = DependencyManager.defaultNodeURL_mainnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_mainnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_mainnet
		tezosChainName = .mainnet
		currentNetworkType = .mainnet
		
		updateKukaiCoreClients()
	}
	
	func setDefaultTestnetURLs() {
		currentNodeURL = DependencyManager.defaultNodeURL_testnet
		currentTzktURL = DependencyManager.defaultTzktURL_mainnet
		currentBcdURL = DependencyManager.defaultBcdURL_testnet
		currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_testnet
		tezosChainName = .hangzhounet
		currentNetworkType = .testnet
		
		updateKukaiCoreClients()
	}
	
	func updateKukaiCoreClients() {
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
		torusAuthService = TorusAuthService(networkType: tezosClientConfig.networkType, networkService: tezosNodeClient.networkService, testnetVerifiers: testnetVerifiers, mainnetVerifiers: testnetVerifiers)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		balanceService = BalanceService()
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		
		networkDidChange = true
	}
}
