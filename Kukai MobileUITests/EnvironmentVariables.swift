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
	let walletAddress_HD_password: String
	let walletAddress_regular: String
	let walletAddress_regular_password: String
	
	let gmailAddress: String
	let gmailPassword: String
	
	private init() {
		/*
		seedPhrase1 = ProcessInfo.processInfo.environment["SEED_PHRASE_1"] ?? ""
		seedPhrasePassword = ProcessInfo.processInfo.environment["SEED_PHRASE_PASSWORD"] ?? ""
		
		walletAddress_HD = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD"] ?? ""
		walletAddress_HD_account_1 = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD_ACCOUNT_1"] ?? ""
		walletAddress_HD_password = ProcessInfo.processInfo.environment["WALLET_ADDRESS_HD_PASSWORD"] ?? ""
		walletAddress_regular = ProcessInfo.processInfo.environment["WALLET_ADDRESS_REGULAR"] ?? ""
		walletAddress_regular_password = ProcessInfo.processInfo.environment["WALLET_ADDRESS_REGULAR_PASSWORD"] ?? ""
		
		gmailAddress = ProcessInfo.processInfo.environment["GMAIL_ADDRESS"] ?? ""
		gmailPassword = ProcessInfo.processInfo.environment["GMAIL_PASSWORD"] ?? ""
		 */
		
		
		seedPhrase1 = "critic click myth problem steak hamster elephant husband region sample rail priority"
		seedPhrasePassword = "abc123def456"
		
		walletAddress_HD = "tz1TmhCvS3ERYpTspQp6TSG5LdqK2JKbDvmv"
		walletAddress_HD_account_1 = "tz1cjAZVh1mb2bskoY23xDHhh137tCnsx3ih"
		walletAddress_HD_password = "tz1LGtCUAc5h3WSFUh7UC2VdaANYYxKfciop"
		walletAddress_regular = "tz1bhLmXQnhyiNtuMSHG934pMbdfiVCa9szz"
		walletAddress_regular_password = "tz1Wj6kenWpyTzPkU8xN9aiRFx2aBVFQ172F"
		
		gmailAddress = "kukaiautomatedtesting@gmail.com"
		gmailPassword = "Tr7LvNOt4xHXDNlLpMB6"
	}
}
