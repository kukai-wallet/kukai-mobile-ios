//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import Foundation
import KukaiCoreSwift

public class TokenDetailsViewModel {
	
	public var symbol = ""
	public var balance = ""
	public var fiat = ""
	public var rate = ""
	
	func loadOfflineData(token: Token) {
		
		symbol = token.symbol
		balance = token.balance.normalisedRepresentation + " \(token.symbol)"
		
		if token.isXTZ() {
			let singleXTZCurrencyString = DependencyManager.shared.coinGeckoService.format(decimal: DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ, numberStyle: .currency, maximumFractionDigits: 2)
			rate = "1 = \(singleXTZCurrencyString)"
			
			let totalXtzValue = (token.balance as? XTZAmount ?? .zero()) * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			fiat = DependencyManager.shared.coinGeckoService.format(decimal: totalXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
		} else if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
			let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			let currencyString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
			
			rate = "1 == \(tokenValueAndRate.marketRate.rounded(scale: 6, roundingMode: .down)) XTZ"
			fiat = currencyString
		}
	}
	
}
