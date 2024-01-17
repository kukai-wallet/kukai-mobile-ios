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
			
			guard let networkStr = record.stringForKey("network"),
				  let network = TezosNodeClientConfig.NetworkType(rawValue: networkStr),
				  let config = record.doubleStringArrayToDict(key1: "keys", key2: "values"),
				  let loginProviderString = config["loginProvider"],
				  let loginProvider = LoginProviders(rawValue: loginProviderString),
				  let authProviderString = config["authProvider"],
				  let authProvider = TorusAuthProvider(rawValue: authProviderString),
				  let type = config["loginType"] else {
					  Logger.app.error("Skipping invalid torus config item: \(record.description)")
					  continue
				  }
			
			// Option 1:
			// Required: loginType, loginProvider, verifierName, redirectURL
			// Optional: aggregateVerifierName, clientId
			if config["jwtDomain"] == nil, let loginType = SubVerifierType(rawValue: type), let verifierName = config["verifierName"], let redirectURL = config["redirectURL"] {
				let details = SubVerifierDetails(loginType: loginType, loginProvider: loginProvider, clientId: config["clientId"] ?? "", verifier: verifierName, redirectURL: redirectURL)
				let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
				verifiers[authProvider] = wrapper
			}
			
			// Option 2:
			// Required: loginType, loginProvider, verifierName, redirectURL
			// Optional: aggregateVerifierName, clientId, browserRedirectURL, jwtDomain
			else if let loginType = SubVerifierType(rawValue: type), let verifierName = config["verifierName"], let redirectURL = config["redirectURL"] {
				
				if let jwtDomain = config["jwtDomain"] {
					var tempParams: [String: String] = [:]
					tempParams["domain"] = jwtDomain
					
					// Check for other optional JWT params
					if let jwtConnection = config["jwtConnection"] {
						tempParams["connection"] = jwtConnection == " " ? "" : jwtConnection // CloudKit dashboard doesn't allow an empty string, Torus needs an empty string for some reason
					}
					if let jwtVerifierIdField = config["jwtVerifierIdField"] {
						tempParams["verifierIdField"] = jwtVerifierIdField
					}
					
					
					let details = SubVerifierDetails(loginType: loginType,
													 loginProvider: loginProvider,
													 clientId: config["clientId"] ?? "",
													 verifier: verifierName,
													 redirectURL: redirectURL,
													 browserRedirectURL: config["browserRedirectURL"],
													 jwtParams: tempParams)
					let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
					verifiers[authProvider] = wrapper
					
				} else {
					let details = SubVerifierDetails(loginType: loginType,
													 loginProvider: loginProvider,
													 clientId: config["clientId"] ?? "",
													 verifier: verifierName,
													 redirectURL: redirectURL,
													 browserRedirectURL: config["browserRedirectURL"])
					let wrapper = SubverifierWrapper(aggregateVerifierName: config["aggregateVerifierName"], networkType: network, subverifier: details)
					verifiers[authProvider] = wrapper
				}
			}
		}
		
		return verifiers
	}
	
	
	
	// MARK: - CloudKit dashboard helpers tools
	
	/*
	 CloudKit dashboard offers no means of exporting / importing data. Below functions are a way to copy the contents of 1 env to another.
	 
	 Requires setting this setting in entitlements: https://stackoverflow.com/questions/30182521/use-production-cloudkit-during-development
	 
	 not working yet, upload fails. Ignoring for now
	 */
	
	/*
	private func writeRecordsTemporarily() {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let docsDirectoryURL = urls[0]
		let ckStyleURL = docsDirectoryURL.appendingPathComponent("ckstylerecords.data")
		
		do {
			let data = try NSKeyedArchiver.archivedData(withRootObject: configItemRecords, requiringSecureCoding: true)
			
			try data.write(to: ckStyleURL, options: .atomic)
			Logger.app.info("CKRecords written to disk")
			
		} catch {
			Logger.app.error("Could not write CKRecords to disk")
		}
	}
	
	private func uploadRecordsIfAvaialble() {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let docsDirectoryURL = urls[0]
		let ckStyleURL = docsDirectoryURL.appendingPathComponent("ckstylerecords.data")
		let dispatchGroup = DispatchGroup()
		
		var newRecords: [CKRecord] = []
		if FileManager.default.fileExists(atPath: ckStyleURL.path) {
			
			do {
				
				// unarchive
				let data = try Data(contentsOf:ckStyleURL)
				if let theRecords: [CKRecord] = try NSKeyedUnarchiver.unarchiveObject(with: data) as? [CKRecord] {
					newRecords = theRecords
					Logger.app.info("CKRecords unarchived. Count is \(newRecords.count)")
				}
				
				
				// upload
				dispatchGroup.enter()
				for record in newRecords {
					dispatchGroup.enter()
					
					database.save(record) { record, error in
						Logger.app.info("Record upload - error: \(error)")
						dispatchGroup.leave()
					}
				}
				dispatchGroup.leave()
				
			} catch {
				Logger.app.error("Could not read CKRecords: \(error)")
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			Logger.app.info("All uploaded")
		}
	}
	
	private func deleteTempRecords() {
		let _ = DiskService.delete(fileName: "ckstylerecords.data")
	}
	*/
}
