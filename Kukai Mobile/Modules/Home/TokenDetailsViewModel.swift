//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import Charts

struct DataSet {
	let data: LineChartDataSet
	let upperLimit: ChartLimitLine
	let lowerLimit: ChartLimitLine
}

struct AllChartData {
	let day: DataSet
	let week: DataSet
	let month: DataSet
	let year: DataSet
}

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
	
	func loadChartData(token: Token, completion: @escaping ((Result<AllChartData, KukaiError>) -> Void)) {
		
		// If XTZ we fetch data from coingecko
		if token.isXTZ() {
			DependencyManager.shared.coinGeckoService.fetchAllChartData { [weak self] result in
				guard let self = self else {
					completion(Result.failure(KukaiError.unknown()))
					return
				}
				
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				completion(Result.success(self.formatData(data: res)))
				return
			}
			
		} else {
			// Else we fetch from dipdup
			guard let exchangeData = DependencyManager.shared.balanceService.exchangeDataForToken(token) else {
				completion(Result.failure(KukaiError.unknown(withString: "Chart data unavailable for this token")))
				return
			}
			
			DependencyManager.shared.dipDupClient.getChartDataFor(exchangeContract: exchangeData.address) { [weak self] result in
				guard let self = self else {
					completion(Result.failure(KukaiError.unknown()))
					return
				}
				
				switch result {
					case .success(let graphData):
						completion(Result.success(self.formatData(data: graphData)))
						
					case .failure(let error):
						completion(Result.failure(KukaiError.internalApplicationError(error: error)))
				}
			}
		}
	}
	
	func formatData(data: [CoinGeckoMarketDataResponse]) -> AllChartData {
		let daySet = createDataSet(for: data[0])
		let weekSet = createDataSet(for: data[1])
		let monthSet = createDataSet(for: data[2])
		let yearSet = createDataSet(for: data[3])
		
		return AllChartData(day: daySet, week: weekSet, month: monthSet, year: yearSet)
	}
	
	func formatData(data: GraphQLResponse<DipDupChartData>) -> AllChartData {
		guard let data = data.data else {
			let emptyData = LineChartDataSet(entries: [], label: "")
			let emptyLimit = ChartLimitLine()
			
			return AllChartData(day: DataSet(data: emptyData, upperLimit: emptyLimit, lowerLimit: emptyLimit),
								week: DataSet(data: emptyData, upperLimit: emptyLimit, lowerLimit: emptyLimit),
								month: DataSet(data: emptyData, upperLimit: emptyLimit, lowerLimit: emptyLimit),
								year: DataSet(data: emptyData, upperLimit: emptyLimit, lowerLimit: emptyLimit))
		}
		
		let daySet = createDataSet(for: data.quotes15mNogaps)
		let weekSet = createDataSet(for: data.quotes1hNogaps)
		let monthSet = createDataSet(for: data.quotes1dNogaps)
		let yearSet = createDataSet(for: data.quotes1wNogaps)
		
		return AllChartData(day: daySet, week: weekSet, month: monthSet, year: yearSet)
	}
	
	func createDataSet(for data: CoinGeckoMarketDataResponse) -> DataSet {
		var setData: [ChartDataEntry] = []
		var setUpper = 1.0
		var setLower = 1.0
		
		for (index, item) in data.prices.enumerated() {
			let val = item[1]
			
			if setUpper == 1.0 || setUpper < val {
				setUpper = val
			}
			
			if setLower == 1.0 || setLower > val {
				setLower = val
			}
			
			setData.append(ChartDataEntry(x: Double(index), y: val))
		}
		
		let chartSet = LineChartDataSet(entries: setData, label: "")
		chartSet.drawIconsEnabled = false
		chartSet.drawCirclesEnabled = false
		chartSet.lineWidth = 3
		//chartSet.circleRadius = 3
		chartSet.drawCircleHoleEnabled = false
		chartSet.setColor(UIColor(named: "primary-button-background") ?? .black)
		chartSet.setCircleColor(UIColor(named: "primary-button-background") ?? .black)
		
		let upperLimitLine = ChartLimitLine(limit: setUpper, label: String(format: "%.2f", setUpper))
		upperLimitLine.lineWidth = 1
		upperLimitLine.lineDashLengths = [5, 5]
		upperLimitLine.lineColor = .black
		upperLimitLine.labelPosition = .rightTop
		upperLimitLine.valueFont = .systemFont(ofSize: 10)
		
		let lowerLimitLine = ChartLimitLine(limit: setLower, label: String(format: "%.2f", setLower))
		lowerLimitLine.lineWidth = 1
		lowerLimitLine.lineDashLengths = [5, 5]
		lowerLimitLine.lineColor = .black
		lowerLimitLine.labelPosition = .leftBottom
		lowerLimitLine.valueFont = .systemFont(ofSize: 10)
		
		return DataSet(data: chartSet, upperLimit: upperLimitLine, lowerLimit: lowerLimitLine)
	}
	
	func createDataSet(for dataArray: [DipDupChartObject]) -> DataSet {
		var setData: [ChartDataEntry] = []
		var setUpper = 1.0
		var setLower = 1.0
		
		for (index, item) in dataArray.enumerated() {
			let val = item.averageDouble()
			
			if setUpper == 1.0 || setUpper < val {
				setUpper = val
			}
			
			if setLower == 1.0 || setLower > val {
				setLower = val
			}
			
			setData.append(ChartDataEntry(x: Double(index), y: val))
		}
		
		let chartSet = LineChartDataSet(entries: setData, label: "")
		chartSet.drawIconsEnabled = false
		chartSet.drawCirclesEnabled = false
		chartSet.lineWidth = 3
		//chartSet.circleRadius = 3
		chartSet.drawCircleHoleEnabled = false
		chartSet.setColor(UIColor(named: "primary-button-background") ?? .black)
		chartSet.setCircleColor(UIColor(named: "primary-button-background") ?? .black)
		
		let upperLimitLine = ChartLimitLine(limit: setUpper, label: String(format: "%.2f", setUpper))
		upperLimitLine.lineWidth = 1
		upperLimitLine.lineDashLengths = [5, 5]
		upperLimitLine.lineColor = .black
		upperLimitLine.labelPosition = .rightTop
		upperLimitLine.valueFont = .systemFont(ofSize: 10)
		
		let lowerLimitLine = ChartLimitLine(limit: setLower, label: String(format: "%.2f", setLower))
		lowerLimitLine.lineWidth = 1
		lowerLimitLine.lineDashLengths = [5, 5]
		lowerLimitLine.lineColor = .black
		lowerLimitLine.labelPosition = .leftBottom
		lowerLimitLine.valueFont = .systemFont(ofSize: 10)
		
		return DataSet(data: chartSet, upperLimit: upperLimitLine, lowerLimit: lowerLimitLine)
	}
}
