//
//  AppUpdateService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/10/2023.
//

import Foundation
import KukaiCoreSwift
import OSLog

public struct MobileVersionData: Codable {
	let ios: MobileVersioniOS
}

public struct MobileVersioniOS: Codable {
	let required: String
	let recommended: String
}

public class AppUpdateService {
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	private let stagingURL = URL(string: "https://staging.services.kukai.app/v1/version")!
	private let prodURL = URL(string: "https://services.kukai.app/v1/version")!
	private let fetchVersionKey = "app-update-version-check"
	
	
	// mt = meida type. 8 = mobile application. See: https://stackoverflow.com/questions/1781427/what-is-mt-8-in-itunes-links-for-the-app-store
	public static let appStoreURL = URL(string: "https://apps.apple.com/ie/app/id1576499860?mt=8")!
	
	public var requiredVersion: String? = nil
	public var isRequiredUpdate = false
	public var recommendedVersion: String? = nil
	public var isRecommendedUpdate = false
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
		
		if let lastCache = self.requestIfService.lastCache(forKey: fetchVersionKey, responseType: MobileVersionData.self) {
			processVersionData(data: lastCache)
		}
	}
	
	public func processVersionData(data: MobileVersionData) {
		requiredVersion = data.ios.required
		recommendedVersion = data.ios.recommended
		
		checkVersions()
	}
	
	public func checkVersions() {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
		let currentAppVersionString = "\(version).\(build)"
		
		isRequiredUpdate = (currentAppVersionString.versionCompare(requiredVersion ?? "1.0.0.0") == .orderedAscending)
		isRecommendedUpdate = (currentAppVersionString.versionCompare(recommendedVersion ?? "1.0.0.0") == .orderedAscending)
	}
	
	public func url() -> URL {
		#if BETA
		os_log("Version checker - using BETA", log: .default, type: .default)
		return stagingURL
		#elseif DEBUG
		os_log("Version checker - using DEBUG", log: .default, type: .default)
		return stagingURL
		#else
		os_log("Version checker - using PROD", log: .default, type: .default)
		return prodURL
		#endif
	}
	
	public func fetchUpdatedVersionDataIfNeeded(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		self.requestIfService.request(url: self.url(), withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.minute.rawValue, forKey: fetchVersionKey, responseType: MobileVersionData.self) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.processVersionData(data: response)
			completion(Result.success(true))
		}
	}
}
