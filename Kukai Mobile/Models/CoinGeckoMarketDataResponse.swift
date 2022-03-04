//
//  CoinGeckoMarketDataResponse.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/03/2022.
//

import Foundation

public struct CoinGeckoMarketDataResponse: Codable {
	public let prices: [[Double]]
}
