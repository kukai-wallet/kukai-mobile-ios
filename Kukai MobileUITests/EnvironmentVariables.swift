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
	
	let walletAddress_HD: String
	let walletAddress_HD_account_1: String
	let walletAddress_HD_account_2: String
	let walletAddress_HD_password: String
	let walletAddress_regular: String
	let walletAddress_regular_password: String
	
	let gmailAddress: String
	let gmailPassword: String
	
	private init() {
		seedPhrase1 = ProcessInfo.processInfo.environment["SEED_PHRASE_1"] ?? ""
		seedPhrasePassword = ProcessInfo.processInfo.environment["SEED_PHRASE_PASSWORD"] ?? ""
		
		walletAddress_HD = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD"] ?? ""
		walletAddress_HD_account_1 = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD_ACCOUNT_1"] ?? ""
		walletAddress_HD_account_2 = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD_ACCOUNT_2"] ?? ""
		walletAddress_HD_password = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD_PASSWORD"] ?? ""
		walletAddress_regular = ProcessInfo.processInfo.environment["WALLET_ADDRESS_REGULAR"] ?? ""
		walletAddress_regular_password = ProcessInfo.processInfo.environment["WALLET_ADDRESS_REGULAR_PASSWORD"] ?? ""
		
		gmailAddress = ProcessInfo.processInfo.environment["GMAIL_ADDRESS"] ?? ""
		gmailPassword = ProcessInfo.processInfo.environment["GMAIL_PASSWORD"] ?? ""
	}
}
