//
//  CoinGeckoMarketDataResponse.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/03/2022.
//

import Foundation

public struct CoinGeckoMarketDataResponse: Codable {
	public let prices: [[Double]]
	
	public func lessThan100Samples() -> [[Double]] {
		var reducedPrices = prices
		while reducedPrices.count > 100 {
			reducedPrices = reducedPrices.enumerated().compactMap({ index, element in
				// Remove the third value, unless its the last
				return (index != reducedPrices.count-1 && index % 3 == 2) ? nil : element
			})
		}
		
		return reducedPrices
	}
}
