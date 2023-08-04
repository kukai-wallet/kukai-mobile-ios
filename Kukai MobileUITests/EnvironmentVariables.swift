//
//  EnvironmentVariables.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 04/08/2023.
//

import Foundation

public struct EnvironmentVariables {
	
	public static let shared = EnvironmentVariables()
	
	let seedPhrase1: String
	let seedPhrasePassword: String
	let gmailAddress: String
	let gmailPassword: String
	
	private init() {
		seedPhrase1 = ProcessInfo.processInfo.environment["SEED_PHRASE_1"] ?? ""
		seedPhrasePassword = ProcessInfo.processInfo.environment["SEED_PHRASE_PASSWORD"] ?? ""
		gmailAddress = ProcessInfo.processInfo.environment["GMAIL_ADDRESS"] ?? ""
		gmailPassword = ProcessInfo.processInfo.environment["GMAIL_PASSWORD"] ?? ""
	}
}
