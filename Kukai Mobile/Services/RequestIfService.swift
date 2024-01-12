//
//  RequestIfService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift
import KukaiCryptoSwift
import OSLog

private struct SecureServiceObject: Codable {
	let data: String
	let signature: String
}

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
	public func request<T: Codable>(url: URL, withBody body: Data?, ifElapsedGreaterThan: TimeInterval, forKey key: String, responseType: T.Type, isSecure: Bool = false, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
		
		if let validObject = checkIfCached(forKey: key, ifElapsedGreaterThan: ifElapsedGreaterThan, forType: T.self) {
			
			// If we have an object sotred on disk, that was stored within the timeframe, extract and return it
			completion(Result.success(validObject))
			
		} else if isSecure {
			
			// Else if its a secure endpoint, fetch, validate, parse and store the data
			self.networkService.request(url: url, isPOST: body != nil, withBody: body, forReturnType: SecureServiceObject.self) { [weak self] result in
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				if let validObject = self?.validate(secureObject: res, responseType: T.self) {
					let _ = DiskService.write(encodable: StorageObject(lastRequested: Date().timeIntervalSince1970, storedData: validObject), toFileName: key)
					completion(Result.success(validObject))
				} else {
					completion(Result.failure(KukaiError.unknown(withString: "Unable to parse secure object")))
				}
			}
		} else {
			
			// Else if not secure endpoint, just fetch and store
			self.networkService.request(url: url, isPOST: body != nil, withBody: body, forReturnType: T.self) { result in
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				let _ = DiskService.write(encodable: StorageObject(lastRequested: Date().timeIntervalSince1970, storedData: res), toFileName: key)
				completion(Result.success(res))
			}
		}
	}
	
	private func checkIfCached<T: Codable>(forKey key: String, ifElapsedGreaterThan: TimeInterval, forType: T.Type) -> T? {
		let currentTimestmap = Date().timeIntervalSince1970
		let lastObj = DiskService.read(type: StorageObject<T>.self, fromFileName: key)
		
		if lastObj == nil || (currentTimestmap - (lastObj?.lastRequested ?? currentTimestmap)) > ifElapsedGreaterThan {
			return nil
			
		} else if let obj = lastObj {
			return obj.storedData
		}
		
		return nil
	}
	
	public func lastCache<T: Codable>(forKey key: String, responseType: T.Type) -> T? {
		let lastObj = DiskService.read(type: StorageObject<T>.self, fromFileName: key)
		return lastObj?.storedData
	}
	
	public func delete(key: String) -> Bool {
		return DiskService.delete(fileName: key)
	}
	
	private func validate<T: Codable>(secureObject: SecureServiceObject, responseType: T.Type) -> T? {
		guard let publicKeyData = try? Data(hexString: "d71729958d14ba994b9bf29816f9710bd944d0ed7dc3e5a58a31532ca87e06f6"),
			  let signatureData = try? Data(hexString: secureObject.signature),
			  let data = Data(base64Encoded: secureObject.data)
		else {
			Logger.app.error("RequestIfService unable to setup secure data processing")
			return nil
		}
		
		let publicKey = PublicKey(publicKeyData.bytes, signingCurve: .ed25519)
		let valid = publicKey.verify(message: data.bytes, signature: signatureData.bytes)
		
		if valid {
			return try? JSONDecoder().decode(T.self, from: data)
		}
		
		return nil
	}
}
