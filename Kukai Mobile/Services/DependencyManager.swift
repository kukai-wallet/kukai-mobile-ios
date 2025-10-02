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
	static let defaultTzktURL_mainnet = URL(string: "https://kukai.api.tzkt.io")!
	static let defaultExplorerURL_mainnet = URL(string: "https://tzkt.io")!
	static let defaultBcdURL_mainnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_mainnet = URL(string: "https://api.tezos.domains/graphql")!
	static let defaultObjktURL_mainnet = URL(string: "https://data.objkt.com/v3/graphql")!
	
	static let defaultNodeURLs_ghostnet = [URL(string: "https://ghostnet.tezos.ecadinfra.com")!, URL(string: "https://rpc.ghostnet.tzboot.net")!, URL(string: "https://ghostnet.smartpy.io")!]
	static let defaultTzktURL_ghostnet = URL(string: "https://api.ghostnet.tzkt.io")!
	static let defaultExplorerURL_ghostnet = URL(string: "https://ghostnet.tzkt.io")!
	static let defaultBcdURL_ghostnet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_ghostnet = URL(string: "https://ghostnet-api.tezos.domains/graphql")!
	static let defaultObjktURL_ghostnet = URL(string: "https://data.ghostnet.objkt.com/v3/graphql")!
	
	static let defaultNodeURLs_shadownet = [URL(string: "https://rpc.shadownet.teztnets.com")!]
	static let defaultTzktURL_shadownet = URL(string: "https://api.shadownet.tzkt.io")!
	static let defaultExplorerURL_shadownet = URL(string: "https://shadownet.tzkt.io")!
	static let defaultBcdURL_shadownet = URL(string: "https://api.better-call.dev")!
	static let defaultTezosDomainsURL_shadownet = URL(string: "https://shadownet-api.tezos.domains/graphql")!
	static let defaultObjktURL_shadownet = URL(string: "https://data.shadownet.objkt.com/v3/graphql")!
	
	static let defaultNodeURLs_protocolnet = [URL(string: "https://rpc.seoulnet.teztnets.com")!]
	static let defaultTzktURL_protocolnet = URL(string: "https://api.seoulnet.tzkt.io")!
	static let defaultExplorerURL_protocolnet = URL(string: "https://seoulnet.tzkt.io")!
	
	static let defaultNodeURLs_nextnet = [URL(string: "https://rpc.nextnet-20250626.teztnets.com")!]
	static let defaultTzktURL_nextnet = URL(string: "https://api.nextnet.tzkt.io")!
	static let defaultExplorerURL_nextnet = URL(string: "https://nextnet.tzkt.io")!
	
	@UserDefaultsBacked(key: "app.kukai.mobile.experimental.node.url")
	var experimentalNodeUrl: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.experimental.tzkt.url")
	var experimentalTzktUrl: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.experimental.explorer.url")
	var experimentalExplorerUrl: URL?
	
	
	
	struct NetworkManagement {
		static let ghostnetFaucet = URL(string: "https://faucet.ghostnet.teztnets.com/")!
		static let shadownetFaucet = URL(string: "https://faucet.shadownet.teztnets.com/")!
		static let protocolnetFaucet = URL(string: "https://faucet.seoulnet.teztnets.com/")!
		static let nextnetFaucet = URL(string: "https://faucet.nextnet-20250626.teztnets.com/")!
		
		static func currentNetworkDisplayName() -> String {
			
			let current = DependencyManager.shared.currentNetworkType
			
			if current == .mainnet || current == .ghostnet || current == .shadownet {
				return current.rawValue.firstUppercased
			} else {
				return current.rawValue.firstUppercased + " (\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName() ?? "..."))"
			}
		}
		
		static func faucet(forNetworkType networkType: TezosNodeClientConfig.NetworkType = DependencyManager.shared.currentNetworkType) -> URL? {
			switch networkType {
				case .ghostnet:
					return ghostnetFaucet
				
				case .shadownet:
					return shadownetFaucet
					
				case .protocolnet:
					return protocolnetFaucet
					
				case .nextnet:
					return nextnetFaucet
					
				default:
					return nil
			}
		}
	}
	
	
	
	// Kukai Core clients and properties
	var tezosClientConfig: TezosNodeClientConfig
	var tezosNodeClient: TezosNodeClient
	var tzktClient: TzKTClient
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
	var torusVerifiers: [TorusAuthProvider: SubverifierWrapper] = [:]
	var torusMainnetKeys: [String: String] = [:]
	var torusTestnetKeys: [String: String] = [:]
	
	// Stored URL's and network info
	@UserDefaultsBacked(key: "app.kukai.mobile.node.url")
	var currentNodeURLs: [URL] = DependencyManager.defaultNodeURLs_mainnet
	
	@UserDefaultsBacked(key: "app.kukai.mobile.tzkt.url")
	var currentTzktURL: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.explorer.url")
	var currentExplorerURL: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.tezos-domains.url")
	var currentTezosDomainsURL: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.objkt.url")
	var currentObjktURL: URL?
	
	@UserDefaultsBacked(key: "app.kukai.mobile.network.url")
	var currentNetworkType: TezosNodeClientConfig.NetworkType = .mainnet
	
	
	
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
	
	var isRpcOnlyMode: Bool {
		return (DependencyManager.shared.currentNetworkType == .experimental && DependencyManager.shared.currentTzktURL == nil)
	}
	
	// For use during WC2 flow where a user tentively selects an account, and we want to wait until its confirmed before switching
	var temporarySelectedWalletMetadata: WalletMetadata?
	var temporarySelectedWalletAddress: String? {
		get {
			return temporarySelectedWalletMetadata?.address
		}
	}
	
	var currencyChanged = false
	
	
	// Combine publishers to serve as notifications across multiple screens
	// `@Published` can't be assigned to a computed property. To avoid loosing ability to wrap around UserDefaults
	// We create dummy published vars, where the actual value isn't relevant, we only care about triggering logic from these when a value is set
	@Published var networkDidChange: Bool = false
	@Published var walletDidChange: Bool = false
	@Published var addressLoaded: String = ""
	@Published var addressRefreshed: String = ""
	@Published var sideMenuOpen: Bool = false
	@Published var walletDeleted: Bool = false
	@Published var loginActive: Bool = false
	
	
	
	
	
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
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		objktClient = ObjktClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, dipDupClient: dipDupClient)
		torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers, web3AuthClientId: "")
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
				
				// Apparently sentry's capture reaches out to [Window screen], which requires being on main thread
				DispatchQueue.main.async {
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
	}
	
	func setNetworkTo(networkTo: TezosNodeClientConfig.NetworkType, supressUpdateNotification: Bool = false) {
		switch networkTo {
			case .mainnet:
				currentNodeURLs = DependencyManager.defaultNodeURLs_mainnet
				currentTzktURL = DependencyManager.defaultTzktURL_mainnet
				currentExplorerURL = DependencyManager.defaultExplorerURL_mainnet
				currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_mainnet
				currentObjktURL = DependencyManager.defaultObjktURL_mainnet
			
			case .shadownet:
				currentNodeURLs = DependencyManager.defaultNodeURLs_shadownet
				currentTzktURL = DependencyManager.defaultTzktURL_shadownet
				currentExplorerURL = DependencyManager.defaultExplorerURL_shadownet
				currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_shadownet
				currentObjktURL = DependencyManager.defaultObjktURL_shadownet
				
			case .ghostnet:
				currentNodeURLs = DependencyManager.defaultNodeURLs_ghostnet
				currentTzktURL = DependencyManager.defaultTzktURL_ghostnet
				currentExplorerURL = DependencyManager.defaultExplorerURL_ghostnet
				currentTezosDomainsURL = DependencyManager.defaultTezosDomainsURL_ghostnet
				currentObjktURL = DependencyManager.defaultObjktURL_ghostnet
				
			case .protocolnet:
				currentNodeURLs = DependencyManager.defaultNodeURLs_protocolnet
				currentTzktURL = DependencyManager.defaultTzktURL_protocolnet
				currentExplorerURL = DependencyManager.defaultExplorerURL_protocolnet
				currentTezosDomainsURL = nil
				currentObjktURL = nil
				
			case .nextnet:
				currentNodeURLs = DependencyManager.defaultNodeURLs_nextnet
				currentTzktURL = DependencyManager.defaultTzktURL_nextnet
				currentExplorerURL = DependencyManager.defaultExplorerURL_nextnet
				currentTezosDomainsURL = nil
				currentObjktURL = nil
				
			case .experimental:
				
				// UI should make sure this never happens by not enabling the switch until a valid value is supplied
				// This is an advanced feature so it should be left empty and only used if users supply a value
				if let nodeURL = DependencyManager.shared.experimentalNodeUrl {
					currentNodeURLs = [nodeURL]
				} else {
					currentNodeURLs = []
				}
				
				// Under this mode, tzkt urls are optional, as they might not be available. The client will simply return an error when used under this mode
				currentTzktURL = DependencyManager.shared.experimentalTzktUrl
				currentExplorerURL = DependencyManager.shared.experimentalExplorerUrl
				currentTezosDomainsURL = nil
				currentObjktURL = nil
		}
		
		currentNetworkType = networkTo
		
		DependencyManager.shared.tezosNodeClient.networkVersion = nil
		updateKukaiCoreClients(supressUpdateNotification: supressUpdateNotification)
	}
	
	func updateKukaiCoreClients(supressUpdateNotification: Bool = false) {
		tzktClient.stopListeningForAccountChanges()
		
		tezosClientConfig = TezosNodeClientConfig.configWithLocalForge(
			nodeURLs: currentNodeURLs,
			tzktURL: currentTzktURL,
			tezosDomainsURL: currentTezosDomainsURL,
			objktApiURL: currentObjktURL,
			urlSession: sharedSession,
			networkType: currentNetworkType
		)
		
		tezosNodeClient = TezosNodeClient(config: tezosClientConfig)
		dipDupClient = DipDupClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		objktClient = ObjktClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig, dipDupClient: dipDupClient)
		coinGeckoService = CoinGeckoService(networkService: tezosNodeClient.networkService)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: tezosClientConfig)
		exploreService = ExploreService(networkService: tezosNodeClient.networkService, networkType: currentNetworkType)
		discoverService = DiscoverService(networkService: tezosNodeClient.networkService)
		appUpdateService = AppUpdateService(networkService: tezosNodeClient.networkService)
		
		coinGeckoService.stubPrice = self.stubXtzPrice
		
		if !supressUpdateNotification {
			exploreService.loadCache()
			networkDidChange = true
		}
	}
	
	func setupTorus() {
		torusAuthService = TorusAuthService(networkService: tezosNodeClient.networkService, verifiers: torusVerifiers, web3AuthClientId: torusMainnetKeys["web3AuthClientId"] ?? "")
	}
}
