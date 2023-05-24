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
	var primaryKey: UUID = UUID()
	
	let name: String
	let address: [String]
	let thumbnailUrl: String
	let discoverUrl: String
	let link: String
	let shouldDisplayLink: ShouldDisplayLink?
	let category: [String]
	let description: String
	let zoomDiscoverImg: Bool?
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
			
			self?.items = Dictionary(uniqueKeysWithValues: response.map({ ($0.primaryKey, $0) }))
			self?.processQuickFindList(items: response)
			
			completion(Result.success(true))
		}
	}
}
