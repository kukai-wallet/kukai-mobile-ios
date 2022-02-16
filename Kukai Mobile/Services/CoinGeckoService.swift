//
//  CoinGeckoService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class CoinGeckService {
	
	private let coinGeckoPriceURL = "https://api.coingecko.com/api/v3/simple/price?ids=tezos&vs_currencies="
	private let coinGeckoExchangeRatesURL = "https://api.coingecko.com/api/v3/exchange_rates"
	
	private let fetchTezosPriceKey = "coingeco-tezos-price"
	private let fetchEchangeRates = "coingeco-exchange-rates"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	var selectedCurrency: String {
		set { UserDefaults.standard.setValue(newValue, forKey: "com.currency.selected") }
		get { return (UserDefaults.standard.string(forKey: "com.currency.selected") ?? Locale.current.currencyCode?.lowercased()) ?? "usd" } // Return stored, or based on phone local, or default to USD
	}
	
	
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
	}
	
	public func fetchTezosPrice(completion: @escaping ((Result<Decimal, ErrorResponse>) -> Void)) {
		guard let url = URL(string: coinGeckoPriceURL + selectedCurrency) else {
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.minute.rawValue, forKey: fetchTezosPriceKey, responseType: CoinGeckoCurrentPrice.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			completion(Result.success(response.price()))
		}
	}
	
	public func fetchExchangeRates(completion: @escaping ((Result<CoinGeckoExchangeRateResponse, ErrorResponse>) -> Void)) {
		guard let url = URL(string: coinGeckoExchangeRatesURL) else {
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: fetchEchangeRates, responseType: CoinGeckoExchangeRateResponse.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			completion(Result.success(response))
		}
	}
}
