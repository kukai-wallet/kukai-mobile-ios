//
//  CloudKitService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/04/2022.
//

import Foundation
import KukaiCoreSwift
import CloudKit
import CustomAuth
import os.log

public class CloudKitService {
	
	private let database = CKContainer.default().publicCloudDatabase
	private var configItemRecords: [CKRecord] = []
	
	public func fetchConfigItems(completion: @escaping ((KukaiError?) -> Void)) {
		let query = CKQuery(recordType: "ConfigItem", predicate: NSPredicate(value: true))
		
		database.fetch(withQuery: query) { [weak self] result in
			switch result {
				case .success(let data):
					
					// Extract all valid records from complex array
					self?.configItemRecords = data.matchResults.map { (id, result) -> CKRecord? in
						guard let res = try? result.get() else {
							return nil
						}
						
						return res
					}.compactMap({ $0 })
					
					DispatchQueue.main.async { completion(nil) }
					
				case .failure(let e):
					DispatchQueue.main.async { completion(KukaiError.internalApplicationError(error: e))  }
			}
		}
	}
	
	public func extractTorusConfig() -> [TorusAuthProvider: SubverifierWrapper] {
		var verifiers: [TorusAuthProvider: SubverifierWrapper] = [:]
		
		for record in configItemRecords where record.stringForKey("serviceId") == "torus" {
			
			// record.stringForKey returns nil, haven't got the slightest clue why. Can only get the `json` key value by fetching all values and parsing
			var jsonString = (record.value(forKey: "values") as? [Any])?[0] as? String
			jsonString = jsonString?.replacingOccurrences(of: "\n", with: "")
			jsonString = jsonString?.replacingOccurrences(of: "\t", with: "")
			
			guard let jsonData = jsonString?.data(using: .utf8),
				  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
				  let verifierTypeString = jsonObject["verifierType"] as? String,
				  let verifierType = verifierTypes(rawValue: verifierTypeString),
				  let networkString = record.stringForKey("network"),
				  let network = TezosNodeClientConfig.NetworkType(rawValue: networkString),
				  let loginProviderString = jsonObject["loginProvider"] as? String,
				  let loginProvider = LoginProviders(rawValue: loginProviderString),
				  let authProviderString = jsonObject["authProvider"] as? String,
				  let authProvider = TorusAuthProvider(rawValue: authProviderString),
				  let loginTypeString = jsonObject["loginType"] as? String,
				  let loginType = SubVerifierType(rawValue: loginTypeString),
				  let clientId = jsonObject["clientId"] as? String,
				  let verifierName = jsonObject["verifierName"] as? String,
				  let redirectURL = jsonObject["redirectURL"] as? String
			else {
				Logger.app.error("Skipping invalid torus config item: \(record.description)")
				continue
			}
			
			var subVerifier: SubVerifierDetails? = nil
			var wrapper: SubverifierWrapper? = nil
			
			
			// Check if we have a jwt dictionary, to decide which subVerfier to create
			if let jwtDict = jsonObject["jwt"] as? [String: String] {
				subVerifier = SubVerifierDetails(loginType: loginType, 
												 loginProvider: loginProvider,
												 clientId: clientId,
												 verifier: verifierName,
												 redirectURL: redirectURL,
												 browserRedirectURL: jsonObject["browserRedirectURL"] as? String, // Think this is unused, just adding in case its needed in the future
												 jwtParams: jwtDict)
			} else {
				subVerifier = SubVerifierDetails(loginType: loginType, 
												 loginProvider: loginProvider,
												 clientId: clientId, 
												 verifier: verifierName,
												 redirectURL: redirectURL)
			}
			
			
			// Check what type of login is being requested, so we can decide what to do with the required aggregate param, that might not be needed
			if let sub = subVerifier, verifierType == .singleLogin {
				wrapper = SubverifierWrapper(aggregateVerifierName: verifierName, verifierType: verifierType, networkType: network, subverifier: sub) // Non-aggregate
				
			} else if let sub = subVerifier, let aggregateVerfifier = jsonObject["aggregateVerifierName"] as? String {
				wrapper = SubverifierWrapper(aggregateVerifierName: aggregateVerfifier, verifierType: verifierType, networkType: network, subverifier: sub) // Aggregate
				
			} else {
				Logger.app.error("Skipping invalid torus config item: \(record.description)")
				continue
			}
			
			verifiers[authProvider] = wrapper
		}
		
		return verifiers
	}
}
