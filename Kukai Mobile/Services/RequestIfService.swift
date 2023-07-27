//
//  RequestIfService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class RequestIfService {
	
	public enum TimeConstants: TimeInterval {
		case second = 1
		case minute = 60
		case fifteenMinute = 900
		case thirtyMinute = 1800
		case hour = 3600
		case day = 86400
		case week = 604800
		case month = 2419200 // 4 weeks
	}
	
	struct StorageObject<T: Codable>: Codable {
		let lastRequested: TimeInterval
		let storedData: T
	}
	
	private let networkService: NetworkService
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
	}
	
	/**
	Send a request to a URL, only if a given time has passed since last request, else return cached version.
	Useful for situations where you don't want to overload a server, enforcing that its only called once per day (for example), while avoiding constantly wrapping functions in date checks
	 */
	public func request<T: Codable>(url: URL, withBody body: Data?, ifElapsedGreaterThan: TimeInterval, forKey key: String, responseType: T.Type, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
		
		let currentTimestmap = Date().timeIntervalSince1970
		let lastObj = DiskService.read(type: StorageObject<T>.self, fromFileName: key)
		
		if lastObj == nil || (currentTimestmap - (lastObj?.lastRequested ?? currentTimestmap)) > ifElapsedGreaterThan {
			
			self.networkService.request(url: url, isPOST: body != nil, withBody: body, forReturnType: T.self) { result in
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				let _ = DiskService.write(encodable: StorageObject(lastRequested: Date().timeIntervalSince1970, storedData: res), toFileName: key)
				completion(Result.success(res))
			}
			
		} else if let obj = lastObj {
			completion(Result.success(obj.storedData))
			
		} else {
			completion(Result.failure(KukaiError.unknown()))
		}
	}
	
	public func lastCache<T: Codable>(forKey key: String, responseType: T.Type) -> T? {
		let lastObj = DiskService.read(type: StorageObject<T>.self, fromFileName: key)
		return lastObj?.storedData
	}
	
	public func delete(key: String) -> Bool {
		return DiskService.delete(fileName: key)
	}
}
