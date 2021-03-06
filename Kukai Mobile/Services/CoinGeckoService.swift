//
//  CoinGeckoService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import Foundation
import KukaiCoreSwift

public class CoinGeckoService {
	
	private let coinGeckoPriceURL = "https://api.coingecko.com/api/v3/simple/price?ids=tezos&vs_currencies="
	private let coinGeckoExchangeRatesURL = "https://api.coingecko.com/api/v3/exchange_rates"
	private let coinGeckoChartURLDay = "https://api.coingecko.com/api/v3/coins/tezos/market_chart?days=1&vs_currency="
	private let coinGeckoChartURLWeek = "https://api.coingecko.com/api/v3/coins/tezos/market_chart?days=7&vs_currency="
	private let coinGeckoChartURLMonth = "https://api.coingecko.com/api/v3/coins/tezos/market_chart?days=30&interval=daily&vs_currency="
	private let coinGeckoChartURLYear = "https://api.coingecko.com/api/v3/coins/tezos/market_chart?days=365&interval=daily&vs_currency="
	
	private let fetchTezosPriceKey = "coingecko-tezos-price"
	private let fetchEchangeRates = "coingecko-exchange-rates"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	public var selectedCurrencyRatePerXTZ: Decimal = 0
	public var exchangeRates: CoinGeckoExchangeRateResponse? = nil
	private var dispatchGroupMarketData = DispatchGroup()
	
	var selectedCurrency: String {
		get { return (UserDefaults.standard.string(forKey: "com.currency.selected") ?? Locale.current.currencyCode?.lowercased()) ?? "usd" } // Return stored, or based on phone local, or default to USD
	}
	
	
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
	}
	
	
	
	// MARK: - Network functions
	
	public func fetchTezosPrice(completion: @escaping ((Result<Decimal, ErrorResponse>) -> Void)) {
		guard let url = URL(string: coinGeckoPriceURL + selectedCurrency) else {
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		// Request from API, no more frequently than once per minute, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.minute.rawValue, forKey: fetchTezosPriceKey, responseType: CoinGeckoCurrentPrice.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self.selectedCurrencyRatePerXTZ = response.price()
			completion(Result.success(response.price()))
		}
	}
	
	public func fetchExchangeRates(completion: @escaping ((Result<CoinGeckoExchangeRateResponse, ErrorResponse>) -> Void)) {
		guard let url = URL(string: coinGeckoExchangeRatesURL) else {
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: fetchEchangeRates, responseType: CoinGeckoExchangeRateResponse.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self.exchangeRates = response
			completion(Result.success(response))
		}
	}
	
	public func fetchChartData(forURL: String, completion: @escaping ((Result<CoinGeckoMarketDataResponse, ErrorResponse>) -> Void)) {
		guard let url = URL(string: forURL) else {
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: fetchEchangeRates, responseType: CoinGeckoMarketDataResponse.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			completion(Result.success(response))
		}
	}
	
	public func fetchAllChartData(completion: @escaping ((Result<[CoinGeckoMarketDataResponse], ErrorResponse>) -> Void)) {
		var error: ErrorResponse? = nil
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		
		var dayResponse: CoinGeckoMarketDataResponse? = nil
		var weekResponse: CoinGeckoMarketDataResponse? = nil
		var monthResponse: CoinGeckoMarketDataResponse? = nil
		var yearResponse: CoinGeckoMarketDataResponse? = nil
		
		
		fetchChartData(forURL: coinGeckoChartURLDay + selectedCurrency) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			dayResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLWeek + selectedCurrency) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			weekResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLMonth + selectedCurrency) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			monthResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLYear + selectedCurrency) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			yearResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		
		// When everything fetched, process data
		dispatchGroupMarketData.notify(queue: .main) {
			if let err = error {
				completion(Result.failure(err))
				
			} else if let day = dayResponse, let week = weekResponse, let month = monthResponse, let year = yearResponse {
				completion(Result.success([day, week, month, year]))
				
			} else {
				completion(Result.failure(ErrorResponse.unknownError()))
			}
		}
	}
	
	public func setSelectedCurrency(currency: String, completion: @escaping ((ErrorResponse?) -> Void)) {
		UserDefaults.standard.setValue(currency, forKey: "com.currency.selected")
		let _ = self.requestIfService.delete(key: fetchTezosPriceKey)
		
		fetchTezosPrice { result in
			guard let response = try? result.get() else {
				completion(result.getFailure())
				return
			}
			
			self.selectedCurrencyRatePerXTZ = response
			completion(nil)
		}
	}
	
	
	
	// MARK: - Formatters and Helpers
	
	public func sharedNumberFormatter() -> NumberFormatter {
		let numberFormatter = NumberFormatter()
		
		// If user has selected a currency from our list, change the symbol
		if let obj = exchangeRates?.rates[selectedCurrency] {
			
			if obj.type == "crypto" {
				// When displaying crypto prices, symbol should always be on the right hand side. But this is not a configurable option
				// Create a locale with a known right hand symbol setting, and change the rest of the settings to the current locale
				let currentLocale = Locale.current
				let cryptoLocale = Locale(identifier: "es_ES")
				
				numberFormatter.locale = cryptoLocale
				numberFormatter.currencyDecimalSeparator = currentLocale.decimalSeparator
				numberFormatter.currencyGroupingSeparator = currentLocale.groupingSeparator
				numberFormatter.decimalSeparator = currentLocale.decimalSeparator
				numberFormatter.groupingSeparator = currentLocale.groupingSeparator
				numberFormatter.currencySymbol = " "+obj.unit
				
				
			} else {
				numberFormatter.currencySymbol = obj.unit
			}
		}
		
		return numberFormatter
	}
	
	public func placeholderCurrencyString() -> String {
		let numberFormatter = sharedNumberFormatter()
		numberFormatter.numberStyle = .currency
		
		return numberFormatter.string(from: 0.00) ?? "0"
	}
	
	public func format(decimal: Decimal, numberStyle: NumberFormatter.Style, maximumFractionDigits: Int? = nil) -> String {
		let numberFormatter = sharedNumberFormatter()
		numberFormatter.numberStyle = numberStyle
		
		if let maxDigits = maximumFractionDigits {
			numberFormatter.maximumFractionDigits = maxDigits
		} else {
			numberFormatter.maximumFractionDigits = (numberStyle == .currency ? 2 : 6)
		}
		
		let decimalRounded = decimal.rounded(scale: numberFormatter.maximumFractionDigits, roundingMode: .down)
		let decimalAsNumber = decimalRounded as NSNumber
		let outputString = numberFormatter.string(from: decimalAsNumber) ?? "0"
		
		return outputString
	}
}
