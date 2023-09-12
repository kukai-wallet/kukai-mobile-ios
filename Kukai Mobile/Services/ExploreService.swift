//
//  ExploreService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/05/2023.
//

import Foundation
import KukaiCoreSwift

public enum ShouldDisplayLink: String, Codable {
	case all
	case none
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

public class ExploreService {
	
	private let exploreURL = "https://services.kukaiwallet.workers.dev/v1/explore"
	
	private let exploreCacheKey = "explore-cahce-key"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	public var contractAddressToPrimaryKeyMap: [String: UUID] = [:]
	public var items: [UUID: ExploreItem] = [:]
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
	}
	
	
	
	// MARK: - Helpers
	
	/// Extract an exploreItem based on a contract address
	public func item(forAddress: String) -> ExploreItem? {
		if let uuid = contractAddressToPrimaryKeyMap[forAddress] {
			return items[uuid]
		}
		
		return nil
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
	
	
	
	// MARK: - Network functions
	
	/// Fetch items, which automatically get primaryKey added. Map them into a dictionary based on UUID and store in `items`
	public func fetchExploreItems(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		guard let url = URL(string: exploreURL) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.fifteenMinute.rawValue, forKey: exploreCacheKey, responseType: [ExploreItem].self) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			for (index, item) in response.enumerated() {
				var temp = item
				temp.sortIndex = index
				self?.items[item.primaryKey] = temp
			}
			
			self?.processQuickFindList(items: response)
			
			completion(Result.success(true))
		}
	}
	
	public func deleteCache() {
		self.requestIfService.delete(key: exploreCacheKey)
	}
}
