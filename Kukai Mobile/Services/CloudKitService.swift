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
	
	public func fetchConfigItems(completion: @escaping ((ErrorResponse?) -> Void)) {
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
					completion(nil)
					
				case .failure(let e):
					completion(ErrorResponse.internalApplicationError(error: e))
			}
		}
	}
	
	public func extractTorusConfig(testnet: Bool) -> [TorusAuthProvider: SubverifierWrapper] {
		var verifiers: [TorusAuthProvider: SubverifierWrapper] = [:]
		
		for record in configItemRecords where record.stringForKey("serviceId") == "torus" && record.stringForKey("network") == (testnet ? "testnet" : "mainnet") {
			
			guard let networkStr = record.stringForKey("network"),
				  let network = TezosNodeClientConfig.NetworkType(rawValue: networkStr),
				  let config = record.doubleStringArrayToDict(key1: "keys", key2: "values"),
				  let provider = config["loginProvider"],
				  let type = config["loginType"],
				  let authProvider = TorusAuthProvider(rawValue: provider) else {
					  os_log("Skipping invalid torus config item: %@", log: .default, type: .error, record.description)
					  continue
				  }
			
			// Option 1:
			// Required: loginType, loginProvider, verifierName, redirectURL
			// Optional: aggregateVerifierName, clientId
			if let loginType = SubVerifierType(rawValue: type), let loginProvider = LoginProviders(rawValue: provider), let verifierName = config["verifierName"], let redirectURL = config["redirectURL"] {
				let details = SubVerifierDetails(loginType: loginType, loginProvider: loginProvider, clientId: config["clientId"] ?? "", verifierName: verifierName, redirectURL: redirectURL)
				let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
				verifiers[authProvider] = wrapper
				
			}
			
			// Option 2:
			// Required: loginType, loginProvider, verifierName, redirectURL
			// Optional: aggregateVerifierName, clientId, browserRedirectURL, jwtDomain
			else if let loginType = SubVerifierType(rawValue: type), let loginProvider = LoginProviders(rawValue: provider), let verifierName = config["verifierName"], let redirectURL = config["redirectURL"] {
				
				if let jwtDomain = config["jwtDomain"] {
					let details = SubVerifierDetails(loginType: loginType,
													 loginProvider: loginProvider,
													 clientId: config["clientId"] ?? "",
													 verifierName: verifierName,
													 redirectURL: redirectURL,
													 browserRedirectURL: config["browserRedirectURL"],
													 jwtParams: ["domain": jwtDomain])
					let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
					verifiers[authProvider] = wrapper
					
				} else {
					let details = SubVerifierDetails(loginType: loginType,
													 loginProvider: loginProvider,
													 clientId: config["clientId"] ?? "",
													 verifierName: verifierName,
													 redirectURL: redirectURL,
													 browserRedirectURL: config["browserRedirectURL"])
					let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
					verifiers[authProvider] = wrapper
				}
			}
		}
		
		return verifiers
	}
}
