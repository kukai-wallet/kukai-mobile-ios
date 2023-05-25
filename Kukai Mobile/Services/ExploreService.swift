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

public struct ExploreItem: Codable {
	let primaryKey: UUID
	var sortIndex: Int
	
	let name: String
	let address: [String]
	let thumbnailUrl: String
	let discoverUrl: String?
	let link: String?
	let shouldDisplayLink: ShouldDisplayLink?
	let category: [String]?
	let description: String?
	let zoomDiscoverImg: Bool?
	
	enum CodingKeys: String, CodingKey {
		case primaryKey
		case sortIndex
		case name
		case address
		case thumbnailUrl
		case discoverUrl
		case link
		case shouldDisplayLink
		case category
		case description
		case zoomDiscoverImg
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		address = try container.decode([String].self, forKey: .address)
		thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
		discoverUrl = try container.decodeIfPresent(String.self, forKey: .discoverUrl)
		link = try container.decodeIfPresent(String.self, forKey: .link)
		shouldDisplayLink = try container.decodeIfPresent(ShouldDisplayLink.self, forKey: .shouldDisplayLink)
		category = try container.decodeIfPresent([String].self, forKey: .category)
		description = try container.decodeIfPresent(String.self, forKey: .description)
		zoomDiscoverImg = try container.decodeIfPresent(Bool.self, forKey: .zoomDiscoverImg)
		
		let storedUUID = try? container.decodeIfPresent(UUID.self, forKey: .primaryKey)
		primaryKey = storedUUID ?? UUID()
		
		let storedSortIndex = try? container.decodeIfPresent(Int.self, forKey: .sortIndex)
		sortIndex = storedSortIndex ?? 0
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(address, forKey: .address)
		try container.encode(thumbnailUrl, forKey: .thumbnailUrl)
		try container.encodeIfPresent(discoverUrl, forKey: .discoverUrl)
		try container.encodeIfPresent(link, forKey: .link)
		try container.encodeIfPresent(shouldDisplayLink, forKey: .shouldDisplayLink)
		try container.encodeIfPresent(category, forKey: .category)
		try container.encodeIfPresent(description, forKey: .description)
		try container.encodeIfPresent(zoomDiscoverImg, forKey: .zoomDiscoverImg)
		try container.encode(primaryKey, forKey: .primaryKey)
		try container.encode(sortIndex, forKey: .sortIndex)
	}
}

public class ExploreService {
	
	private let exploreURL = "https://explore.kukaiwallet.workers.dev/"
	
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
			for address in item.address {
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
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: exploreCacheKey, responseType: [ExploreItem].self) { [weak self] result in
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
}
