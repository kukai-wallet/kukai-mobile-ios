//
//  EnvironmentService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/03/2023.
//

import Foundation
import KukaiCoreSwift
import OSLog

public struct Environment: Codable {
	let contractAliases: [EnvirnomentContractAlias]
}

public struct EnvirnomentContractAlias: Codable {
	let name: String
	let address: [String]
	let thumbnailUrl: String
	let link: String
	let category: [String]
	let description: String
}

public class EnvironmentService {
	
	private let mainnetFilename = "mainnet-env"
	
	public let mainnetEnv: Environment
	
	public init() {
		mainnetEnv = EnvironmentService.envFile(fromFilename: mainnetFilename) ?? Environment(contractAliases: [])
	}
	
	private static func envFile(fromFilename filename: String) -> Environment? {
		guard let path = Bundle.main.url(forResource: filename, withExtension: "json"), let envData = try? Data(contentsOf: path) else {
			return nil
		}
		
		do {
			return try JSONDecoder().decode(Environment.self, from: envData)
		} catch {
			os_log("Environment: JSON decode error: %@", "\(error)")
			return nil
		}
	}
}
