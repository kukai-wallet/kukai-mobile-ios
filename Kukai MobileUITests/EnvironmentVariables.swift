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
		/*config1 = ProcessInfo.processInfo.environment["CONFIG_1"] ?? ""
		config2 = ProcessInfo.processInfo.environment["CONFIG_2"] ?? ""
		config3 = ProcessInfo.processInfo.environment["CONFIG_3"] ?? ""*/
		
		config1 = "display bicycle powder festival suggest fire sunny nice tribe mammal hybrid merge merit inquiry dice rose area hover entry casino ranch seat banner there;abc123def456;tz1Z8E2gMHLXFcGGzW68B5e1Vk49FpHQd7xc;tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ;tz1UFXQksYB11kzfuVczhg6ktqiJTuyMSBtB;tz1KiZDCQecjGjM314tFVW44R9pxu1q8zynu;tz1Koy9d5Bd6Ap8nW3riS2g77rGm6rLLj4mF;tz1RozkfZuEcDYmYKbHybhULthDSzwfKqAYQ;kukaiautomatedtesting@gmail.com;Tr7LvNOt4xHXDNlLpMB6"
		
		config2 = "critic click myth problem steak hamster elephant husband region sample rail priority;abc123def456;tz1TmhCvS3ERYpTspQp6TSG5LdqK2JKbDvmv;tz1cjAZVh1mb2bskoY23xDHhh137tCnsx3ih;tz1VG4PerYiMWsZdNbS1Nr4WpNNwuxsLjUrk;tz1LGtCUAc5h3WSFUh7UC2VdaANYYxKfciop;tz1bhLmXQnhyiNtuMSHG934pMbdfiVCa9szz;tz1Wj6kenWpyTzPkU8xN9aiRFx2aBVFQ172F;kukaiautomatedtesting@gmail.com;Tr7LvNOt4xHXDNlLpMB6"
		
		config3 = "tornado include amateur clean keen save lunar actor system choose injury resource picnic nurse helmet argue join trouble together tourist evidence expect father control;abc123def456;tz1f5CiFEXTGj1muecb3Hhqj6riMZqBuPkgY;tz1VYK6CkP9FPC8WMLKVKxuXs3x3c6GQSNuj;tz1gTYNtc6arN6ixBGR6rcB4wzGjgyG5mieM;tz1hqAhTHPvCR5Nz4dyAjiqse7bZEZ8ac2zb;tz1PZXaHJ18fGFcXpape5ddnwRg9VNRWkAL3;tz1SoPvEkXKaLz2gKeKUarAN74mrsiUngKqE;kukaiautomatedtesting@gmail.com;Tr7LvNOt4xHXDNlLpMB6"
		
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
