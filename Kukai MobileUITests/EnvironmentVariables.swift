//
//  EnvironmentVariables.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 04/08/2023.
//

import UIKit

public struct TestConfig {
	let seed: String
	let password: String
	
	let walletAddress_HD: String
	let walletAddress_HD_account_1: String
	let walletAddress_HD_account_2: String
	let walletAddress_HD_password: String
	let walletAddress_regular: String
	let walletAddress_regular_password: String
	let gmailAddress: String
	let gmailPassword: String
}

public struct EnvironmentVariables {
	
	public static let shared = EnvironmentVariables()
	
	private let config1: String
	private let config2: String
	private let config3: String
	
	private var extractedConfigs: [Int: TestConfig] = [:]
	
	private init() {
		let testBundle = Bundle(for: SharedHelpers.self)
		let config1URL = testBundle.url(forResource: "CONFIG_1", withExtension: "txt", subdirectory: "Configs")
		let config2URL = testBundle.url(forResource: "CONFIG_2", withExtension: "txt", subdirectory: "Configs")
		let config3URL = testBundle.url(forResource: "CONFIG_3", withExtension: "txt", subdirectory: "Configs")
		
		// In order to more easily support running locally, and running remotely, check first if files (that will NOT be committed to git) exist. If not, fall back to env variables
		if (ProcessInfo.processInfo.environment["CONFIG_1"] == nil || ProcessInfo.processInfo.environment["CONFIG_1"] == ""),  let config1Path = config1URL, let config2Path = config2URL, let config3Path = config3URL {
			config1 = (try? String(contentsOf: config1Path)) ?? ""
			config2 = (try? String(contentsOf: config2Path)) ?? ""
			config3 = (try? String(contentsOf: config3Path)) ?? ""
			
		} else {
			config1 = ProcessInfo.processInfo.environment["CONFIG_1"] ?? ""
			config2 = ProcessInfo.processInfo.environment["CONFIG_2"] ?? ""
			config3 = ProcessInfo.processInfo.environment["CONFIG_3"] ?? ""
		}
		
		extractedConfigs = [
			1: convertStringToConfig(config1),
			2: convertStringToConfig(config2),
			3: convertStringToConfig(config3)
		]
	}
	
	private func convertStringToConfig(_ configString: String) -> TestConfig {
		let componenets = configString.components(separatedBy: ";")
		
		return TestConfig(seed: componenets[0],
						  password: componenets[1],
						  walletAddress_HD: componenets[2],
						  walletAddress_HD_account_1: componenets[3],
						  walletAddress_HD_account_2: componenets[4],
						  walletAddress_HD_password: componenets[5],
						  walletAddress_regular: componenets[6],
						  walletAddress_regular_password: componenets[7],
						  gmailAddress: componenets[8],
						  gmailPassword: componenets[9])
	}
	
	public func config() -> TestConfig {
		let modelName = UIDevice.modelName
		
		if modelName == "Simulator iPhone SE (3rd generation)" {
			return extractedConfigs[1]!
			
		} else if modelName == "Simulator iPhone 14 Pro" {
			return extractedConfigs[2]!
			
		} else {
			return extractedConfigs[3]!
		}
	}
}
