//
//  CoinGeckoExchangeRateResponse.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation

// MARK: - Exhcnage Rates

public struct CoinGeckoExchangeRateResponse: Codable {
	let rates: [String: CoinGeckoExchangeRate]
}

public struct CoinGeckoExchangeRate: Codable {
	let name: String
	let unit: String
	let value: Decimal
	let type: String
}


// MARK: - Current Price

public struct CoinGeckoCurrentPrice: Codable {
	let tezos: [String: Decimal]
	
	func price() -> Decimal {
		guard let firstKey = tezos.keys.first, let price = tezos[firstKey] else {
			return 0
		}
		
		return price
	}
}
