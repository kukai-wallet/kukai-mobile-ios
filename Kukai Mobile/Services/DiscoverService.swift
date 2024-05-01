//
//  DiscoverService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/07/2023.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import OSLog

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
	
	@URLFromString public var squareLogoUri: URL?
	@URLFromString public var wideLogoUri: URL?
	@URLFromString public var projectUrl: URL?
	
	public var mobileBannerUri: String?
	public var featuredItemURL: URL? {
		guard let stringURL = mobileBannerUri else { return nil }
		
		let scale = UIScreen.main.scale
		if scale == 2 {
			return URL(string: "\(stringURL)300")
		} else {
			return URL(string: "\(stringURL)450")
		}
	}
}

public class DiscoverService {
	
	private let discoverURL_mainnet = "https://services.kukai.app/v4/discover?encode=true"
	private let discoverURL_ghostnet = "https://services.ghostnet.kukai.app/v4/discover?encode=true"
	
	private let discoverCacheKey_mainnet = "discover-cache-key-mainnet"
	private let discoverCacheKey_ghostnet = "discover-cache-key-ghostnet"
	
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
		let currentNetworkType = DependencyManager.shared.currentNetworkType
		let urlToUse = currentNetworkType == .mainnet ? discoverURL_mainnet : discoverURL_ghostnet
		let cacheKeyToUse = currentNetworkType == .mainnet ? discoverCacheKey_mainnet : discoverCacheKey_ghostnet
		
		guard let url = URL(string: urlToUse) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.fifteenMinute.rawValue, forKey: cacheKeyToUse, responseType: [DiscoverGroup].self, isSecure: true) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.items = response
			completion(Result.success(true))
		}
	}
	
	public func deleteCache() {
		let _ = self.requestIfService.delete(key: discoverCacheKey_mainnet)
		let _ = self.requestIfService.delete(key: discoverCacheKey_ghostnet)
	}
}
