//
//  DiscoverService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/07/2023.
//

import Foundation
import KukaiCoreSwift

public struct DiscoverGroup: Codable, Hashable, Identifiable {
	@DefaultUUID public var id: UUID
	
	public let title: String
	public let items: [DiscoverItem]
}

public struct DiscoverItem: Codable, Hashable, Identifiable {
	@DefaultUUID public var id: UUID
	
	public let title: String
	public let categories: [String]
	public let description: String
	
	@URLFromString public var imageUri: URL?
	@URLFromString public var projectURL: URL?
}

public class DiscoverService {
	
	private let discoverURL = "https://services.kukaiwallet.workers.dev/v1/discover"
	
	private let discoverCacheKey = "discover-cahce-key"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	public var items: [DiscoverGroup] = []
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
	}
	
	
	
	// MARK: - Network functions
	
	/// Fetch items, which automatically get primaryKey added. Map them into a dictionary based on UUID and store in `items`
	public func fetchItems(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		guard let url = URL(string: discoverURL) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.hour.rawValue, forKey: discoverCacheKey, responseType: [DiscoverGroup].self) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.items = response
			completion(Result.success(true))
		}
	}
}
