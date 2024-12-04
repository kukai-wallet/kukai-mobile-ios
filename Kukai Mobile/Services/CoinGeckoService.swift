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
	private let fetchEchangeRatesKey = "coingecko-exchange-rates"
	private let chartDataDayKey = "coingecko-chart-day"
	private let chartDataWeekKey = "coingecko-chart-week"
	private let chartDataMonthKey = "coingecko-chart-month"
	private let chartDataYearKey = "coingecko-chart-year"
	
	private let networkService: NetworkService
	private let requestIfService: RequestIfService
	
	public var selectedCurrencyRatePerXTZ: Decimal = -1
	public var exchangeRates: CoinGeckoExchangeRateResponse? = nil
	
	/// Coingecko has a very aggressive rate limiting policy. To avoid issues arising from running XCUITests on dev machine, we stub it during test runs
	public var stubPrice: Bool = false
	
	private var dispatchGroupMarketData = DispatchGroup()
	private var coinGeckoQueue = DispatchQueue(label: "coingecko", qos: .utility)
	
	var selectedCurrency: String {
		get { return (UserDefaults.standard.string(forKey: "com.currency.selected") ?? Locale.current.currency?.identifier.lowercased()) ?? "usd" } // Return stored, or based on phone local, or default to USD
	}
	
	
	
	public init(networkService: NetworkService) {
		self.networkService = networkService
		self.requestIfService = RequestIfService(networkService: networkService)
	}
	
	
	
	// MARK: - Network functions
	
	public func fetchTezosPrice(completion: @escaping ((Result<Decimal, KukaiError>) -> Void)) {
		guard stubPrice == false else {
			selectedCurrencyRatePerXTZ = 1.23
			completion(Result.success(selectedCurrencyRatePerXTZ))
			return
		}
		
		guard let url = URL(string: coinGeckoPriceURL + selectedCurrency) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per minute, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.minute.rawValue, forKey: fetchTezosPriceKey, responseType: CoinGeckoCurrentPrice.self) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.selectedCurrencyRatePerXTZ = response.price()
			completion(Result.success(response.price()))
		}
	}
	
	public func loadLastTezosPrice() {
		guard stubPrice == false else {
			selectedCurrencyRatePerXTZ = 1.23
			return
		}
		
		let cache = self.requestIfService.lastCache(forKey: fetchTezosPriceKey, responseType: CoinGeckoCurrentPrice.self)
		self.selectedCurrencyRatePerXTZ = cache?.price() ?? 0
	}
	
	public func fetchExchangeRates(completion: @escaping ((Result<CoinGeckoExchangeRateResponse, KukaiError>) -> Void)) {
		guard stubPrice == false else {
			let stubbedResponse = CoinGeckoExchangeRateResponse(rates: [
				"usd": CoinGeckoExchangeRate(name: "US Dollar", unit: "$", value: 72729.208, type: "fiat"),
				"eur": CoinGeckoExchangeRate(name: "Euro", unit: "€", value: 66522.788, type: "fiat"),
				"gbp": CoinGeckoExchangeRate(name: "British Pound Sterling", unit: "£", value: 56829.149, type: "fiat")
			])
			
			coinGeckoQueue.sync { [weak self] in
				self?.exchangeRates = stubbedResponse
			}
			completion(Result.success(stubbedResponse))
			return
		}
		
		guard let url = URL(string: coinGeckoExchangeRatesURL) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: fetchEchangeRatesKey, responseType: CoinGeckoExchangeRateResponse.self) { [weak self] result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.coinGeckoQueue.sync { [weak self] in
				self?.exchangeRates = response
			}
			completion(Result.success(response))
		}
	}
	
	public func loadLastExchangeRates() {
		guard stubPrice == false else {
			let stubbedResponse = CoinGeckoExchangeRateResponse(rates: [
				"usd": CoinGeckoExchangeRate(name: "US Dollar", unit: "$", value: 72729.208, type: "fiat"),
				"eur": CoinGeckoExchangeRate(name: "Euro", unit: "€", value: 66522.788, type: "fiat"),
				"gbp": CoinGeckoExchangeRate(name: "British Pound Sterling", unit: "£", value: 56829.149, type: "fiat")
			])
			coinGeckoQueue.sync { [weak self] in
				self?.exchangeRates = stubbedResponse
			}
			return
		}
		
		coinGeckoQueue.sync { [weak self] in
			self?.exchangeRates = self?.requestIfService.lastCache(forKey: self?.fetchEchangeRatesKey ?? "", responseType: CoinGeckoExchangeRateResponse.self)
		}
	}
	
	public func fetchChartData(forURL: String, withKey: String, completion: @escaping ((Result<CoinGeckoMarketDataResponse, KukaiError>) -> Void)) {
		guard stubPrice == false else {
			let stubbedResponse = CoinGeckoMarketDataResponse(prices: [ [1710253206577, 1.364924598389686],
																		[1710253506313, 1.3640842444632224],
																		[1710253815819, 1.366669129944549],
																		[1710254095138, 1.367196961260544],
																		[1710254453439, 1.3661190435663413],
																		[1710254710709, 1.364264674621857],
																		[1710254995244, 1.3664442887113173],
																		[1710255294877, 1.3631232865975842],
																		[1710255623763, 1.3593348486343222],
																		[1710255896593, 1.3527296112320508]])
			completion(Result.success(stubbedResponse))
			return
		}
		
		guard let url = URL(string: forURL) else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		// Request from API, no more frequently than once per day, else read cache
		self.requestIfService.request(url: url, withBody: nil, ifElapsedGreaterThan: RequestIfService.TimeConstants.day.rawValue, forKey: withKey, responseType: CoinGeckoMarketDataResponse.self) { result in
			guard let response = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			completion(Result.success(response))
		}
	}
	
	public func deleteAllCaches() {
		let _ = self.requestIfService.delete(key: fetchTezosPriceKey)
		let _ = self.requestIfService.delete(key: fetchEchangeRatesKey)
		let _ = self.requestIfService.delete(key: chartDataDayKey)
		let _ = self.requestIfService.delete(key: chartDataWeekKey)
		let _ = self.requestIfService.delete(key: chartDataMonthKey)
		let _ = self.requestIfService.delete(key: chartDataYearKey)
	}
	
	public func fetchAllChartData(completion: @escaping ((Result<[CoinGeckoMarketDataResponse], KukaiError>) -> Void)) {
		var error: KukaiError? = nil
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		dispatchGroupMarketData.enter()
		
		var dayResponse: CoinGeckoMarketDataResponse? = nil
		var weekResponse: CoinGeckoMarketDataResponse? = nil
		var monthResponse: CoinGeckoMarketDataResponse? = nil
		var yearResponse: CoinGeckoMarketDataResponse? = nil
		
		
		fetchChartData(forURL: coinGeckoChartURLDay + selectedCurrency, withKey: chartDataDayKey) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			dayResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLWeek + selectedCurrency, withKey: chartDataWeekKey) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			weekResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLMonth + selectedCurrency, withKey: chartDataMonthKey) { [weak self] result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				self?.dispatchGroupMarketData.leave()
				return
			}
			
			monthResponse = res
			self?.dispatchGroupMarketData.leave()
		}
		
		fetchChartData(forURL: coinGeckoChartURLYear + selectedCurrency, withKey: chartDataYearKey) { [weak self] result in
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
				completion(Result.failure(KukaiError.unknown()))
			}
		}
	}
	
	public func setSelectedCurrency(currency: String, completion: @escaping ((KukaiError?) -> Void)) {
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
	
	/**
	 In situations where no pricing infomration is available, we may want to display somehting other than, e.g. $0.00, to indicate the the difference between a token of value lower than 0.01
	 This will instead produce "$--" (localised), to indicate, no info available
	 */
	public func dashedCurrencyString() -> String {
		let numberFormatter = sharedNumberFormatter()
		numberFormatter.numberStyle = .currency
		numberFormatter.maximumFractionDigits = 0
		
		var sampleString = numberFormatter.string(from: 1) ?? "--"
		sampleString = sampleString.replacingOccurrences(of: "1", with: "--")
		
		return sampleString
	}
	
	public func dashedString() -> String {
		return "--"
	}
	
	public func placeholderCurrencyString() -> String {
		let numberFormatter = sharedNumberFormatter()
		numberFormatter.numberStyle = .currency
		
		return numberFormatter.string(from: 0.00) ?? "0"
	}
	
	public func format(decimal: Decimal, numberStyle: NumberFormatter.Style, allowNegative: Bool = false, maximumFractionDigits: Int? = nil) -> String {
		let numberFormatter = sharedNumberFormatter()
		numberFormatter.numberStyle = numberStyle
		
		guard decimal >= 0 || allowNegative else {
			if numberStyle == .decimal {
				return dashedString()
			} else {
				return dashedCurrencyString()
			}
		}
		
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
	
	func formatLargeTokenDisplay(_ num: Decimal, decimalPlaces: Int, includeThousand: Bool = false, allowNegative: Bool, maximumFractionDigits: Int = 3) -> String {
		var reducedNumber: Decimal = 0
		var reducedNumberSymbol: String? = nil
		
		switch abs(num) {
			case 1_000_000_000_000...:
				reducedNumber = num / 1_000_000_000
				reducedNumberSymbol = "t"
				
			case 1_000_000_000...:
				reducedNumber = num / 1_000_000_000
				reducedNumberSymbol = "b"
				
			case 1_000_000...:
				reducedNumber = num / 1_000_000
				reducedNumberSymbol = "m"
			
			case 1_000... where includeThousand:
				reducedNumber = num / 1_000
				reducedNumberSymbol = "k"
			
			case 0...:
				reducedNumber = num
				
			default:
				reducedNumber = num
		}
		
		var stringToReturn = ""
		if let symbol = reducedNumberSymbol {
			stringToReturn = format(decimal: reducedNumber, numberStyle: .decimal, allowNegative: allowNegative, maximumFractionDigits: maximumFractionDigits)
			stringToReturn += symbol
			
		} else {
			stringToReturn = format(decimal: reducedNumber, numberStyle: .decimal, allowNegative: allowNegative, maximumFractionDigits: decimalPlaces)
		}
		
		return stringToReturn
	}
}
