//
//  ExploreService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/05/2023.
//

import Foundation
import KukaiCoreSwift

public struct ExploreEnvironment: Codable {
	let blockList: [String]
	let model3DAllowList: [String]
	let contractAliases: [ExploreItem]
}

public struct ExploreItem: Codable {
	let primaryKey: UUID
	var sortIndex: Int
	
	let name: String
	let contractAddresses: [String]
	let description: String?
	let thumbnailImageUrl: URL?
	let discover: RemoteDiscoverItem?
	
	enum CodingKeys: String, CodingKey {
		case primaryKey
		case sortIndex
		case name
		case contractAddresses
		case description
		case thumbnailImageUrl
		case discover
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		contractAddresses = try container.decode([String].self, forKey: .contractAddresses)
		
		if let urlString = try container.decodeIfPresent(String.self, forKey: .thumbnailImageUrl) { thumbnailImageUrl = URL(string: urlString) } else { thumbnailImageUrl = nil }
		description = try container.decodeIfPresent(String.self, forKey: .description)
		discover = try container.decodeIfPresent(RemoteDiscoverItem.self, forKey: .discover)
		
		let storedUUID = try? container.decodeIfPresent(UUID.self, forKey: .primaryKey)
		primaryKey = storedUUID ?? UUID()
		
		let storedSortIndex = try? container.decodeIfPresent(Int.self, forKey: .sortIndex)
		sortIndex = storedSortIndex ?? 0
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(contractAddresses, forKey: .contractAddresses)
		try container.encode(thumbnailImageUrl?.absoluteString, forKey: .thumbnailImageUrl)
		try container.encode(description, forKey: .description)
		try container.encode(discover, forKey: .discover)
		
		try container.encode(primaryKey, forKey: .primaryKey)
		try container.encode(sortIndex, forKey: .sortIndex)
	}
}

public struct RemoteDiscoverItem: Codable {
	let dappUrl: URL?
	let category: [String]?
	let discoverImageUrl: URL?
	let hasZoomDiscoverImage: Bool?
	
	enum CodingKeys: String, CodingKey {
		case dappUrl
		case category
		case discoverImageUrl
		case hasZoomDiscoverImage
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let urlString = try container.decodeIfPresent(String.self, forKey: .dappUrl) { dappUrl = URL(string: urlString) } else { dappUrl = nil }
		if let urlString = try container.decodeIfPresent(String.self, forKey: .discoverImageUrl) { discoverImageUrl = URL(string: urlString) } else { discoverImageUrl = nil }
		category = try container.decodeIfPresent([String].self, forKey: .category)
		hasZoomDiscoverImage = try container.decodeIfPresent(Bool.self, forKey: .hasZoomDiscoverImage)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(dappUrl?.absoluteString, forKey: .dappUrl)
		try container.encode(category, forKey: .category)
		try container.encode(discoverImageUrl?.absoluteString, forKey: .discoverImageUrl)
		try container.encode(hasZoomDiscoverImage, forKey: .hasZoomDiscoverImage)
	}
}





public class ExploreService {
	
	private let exploreURL_mainnet = "https://services.kukai.app/v4/explore?encode=true"
	private let exploreURL_ghostnet = "https://services.ghostnet.kukai.app/v4/explore?encode=true"
	
	private let exploreCacheKey_mainnet = "explore-cache-key-mainnet"
	private let exploreCacheKey_ghostnet = "explore-cache-key-ghostnet"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	private let networkType: TezosNodeClientConfig.NetworkType
	
	public var contractAddressToPrimaryKeyMap: [String: UUID] = [:]
	public var items: [UUID: ExploreItem] = [:]
	public var blocklistMap: [String: Bool] = [:]
	
	public init(networkService: NetworkService, networkType: TezosNodeClientConfig.NetworkType) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
		self.networkType = networkType
	}
	
	
	
	// MARK: - Helpers
	
	/// Extract an exploreItem based on a contract address
	public func item(forAddress: String) -> ExploreItem? {
		if items.count == 0 {
			loadCache()
		}
		
		if let uuid = contractAddressToPrimaryKeyMap[forAddress] {
			return items[uuid]
		}
		
		return nil
	}
	
	public func isBlocked(forAddress: String?) -> Bool {
		guard let address = forAddress else { return false } // reduce code needed for calling code involving complex fetch/sort/filtering
		
		return self.blocklistMap[address] == true
	}
	
	/// Create a mapping of each address to the corresponding primaryKey of each item, so that lookups can be prefromed in a constant time
	private func processQuickFindList(items: [ExploreItem]) {
		contractAddressToPrimaryKeyMap = [:]
		
		for item in items {
			for address in item.contractAddresses {
				contractAddressToPrimaryKeyMap[address] = item.primaryKey
			}
		}
	}
	
	private func processRawData(item: ExploreEnvironment?) {
		guard let exploreItem = item else {
			return
		}
		
		self.contractAddressToPrimaryKeyMap = [:]
		self.items = [:]
		self.blocklistMap = [:]
		
		for (index, item) in exploreItem.contractAliases.enumerated() {
			var temp = item
			temp.sortIndex = index
			self.items[item.primaryKey] = temp
		}
		
		self.processQuickFindList(items: exploreItem.contractAliases)
		
		for address in exploreItem.blockList {
			blocklistMap[address] = true
		}
	}
	
	
	// MARK: - Network functions
	
	/// Fetch items, which automatically get primaryKey added. Map them into a dictionary based on UUID and store in `items`
	public func fetchExploreItems(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		let currentNetworkType = DependencyManager.shared.currentNetworkType
		let urlToUse = currentNetworkType == .mainnet ? exploreURL_mainnet : exploreURL_ghostnet
		let cacheKeyToUse = currentNetworkType == .mainnet ? exploreCacheKey_mainnet : exploreCacheKey_ghostnet
		
		guard let url = URL(string: urlToUse) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.hour.rawValue, forKey: cacheKeyToUse, responseType: ExploreEnvironment.self, isSecure: true) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.processRawData(item: response)
			
			completion(Result.success(true))
		}
	}
	
	public func loadCache() {
		let cacheKeyToUse = networkType == .mainnet ? exploreCacheKey_mainnet : exploreCacheKey_ghostnet
		let lastCache = self.requestIfService.lastCache(forKey: cacheKeyToUse, responseType: ExploreEnvironment.self)
		processRawData(item: lastCache)
	}
	
	public func deleteCache() {
		let _ = self.requestIfService.delete(key: exploreCacheKey_mainnet)
		let _ = self.requestIfService.delete(key: exploreCacheKey_ghostnet)
	}
}
