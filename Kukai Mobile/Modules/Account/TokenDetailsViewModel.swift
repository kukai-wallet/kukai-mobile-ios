//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift

struct AllChartData {
	let day: [ChartViewDataPoint]
	let week: [ChartViewDataPoint]
	let month: [ChartViewDataPoint]
	let year: [ChartViewDataPoint]
}

public class TokenDetailsViewModel: ViewModel {
	
	private let bakerRewardsCacheFilename = "TokenDetailsViewModel-baker-rewards-xtz"
	
	var tokenIcon: UIImage? = nil
	var tokenIconURL: URL? = nil
	var tokenSymbol = ""
	var tokenFiatPrice = ""
	var tokenPriceChange = ""
	var tokenPriceChangeIsUp = false
	var tokenPriceDateText = ""
	
	var tokenIsFavourited = false
	var tokenCanBeUnFavourited = false
	var tokenIsHidden = false
	var tokenCanBeHidden = false
	var tokenCanBePurchased = false
	
	var tokenBalance = ""
	var tokenValue = ""
	
	var isStaked = false
	var isStakingPossible = false
	
	var bakerText = ""
	
	var previousBakerIconURL: URL? = nil
	var previousBakerAmountTitle = ""
	var previousBakerAmount = ""
	var previousBakerTimeTitle = ""
	var previousBakerTime = ""
	var previousBakerCycleTitle = ""
	var previousBakerCycle = ""
	
	var nextBakerIconURL: URL? = nil
	var nextBakerAmount = ""
	var nextBakerTime = ""
	var nextBakerCycle = ""
	
	
	
	func loadTokenData(token: Token) {
		tokenSymbol = token.symbol
		tokenBalance = token.balance.normalisedRepresentation + " \(token.symbol)"
		
		if token.isXTZ() {
			tokenIcon = UIImage(named: "tezos-logo")
			tokenSymbol = "Tezos"
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			tokenPriceChange = "0.79%"
			tokenPriceChangeIsUp = true
			tokenPriceDateText = "Today"
			
			tokenIsFavourited = true
			tokenCanBeUnFavourited = false
			tokenIsHidden = false
			tokenCanBeHidden = false
			tokenCanBePurchased = true
			
			let account = DependencyManager.shared.balanceService.account
			let xtzValue = (token.balance as? XTZAmount ?? .zero()) * fiatPerToken
			tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			isStakingPossible = true
			if account.delegate != nil {
				isStaked = true
			}
			
			self.state = .success(nil)
			
		} else if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
			tokenIconURL = token.thumbnailURL
			
			let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
			
			isStakingPossible = false
			self.state = .success(nil)
		}
	}
	
	func loadBakerData(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		let account = DependencyManager.shared.balanceService.account
		guard let delegate = account.delegate else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find baker details")))
			return
		}
		
		if let bakerRewardCache = DiskService.read(type: AggregateRewardInformation.self, fromFileName: bakerRewardsCacheFilename), !bakerRewardCache.isOutOfDate(), !bakerRewardCache.moreThan1CycleBetweenPreiousAndNext() {
			updateBakerInfo(from: bakerRewardCache, andDelegate: delegate)
			completion(Result.success(true))
			
		} else {
			DependencyManager.shared.tzktClient.estimateLastAndNextReward(forAddress: account.walletAddress, delegate: delegate) { [weak self] result in
				if let res = try? result.get(), let filename = self?.bakerRewardsCacheFilename {
					self?.updateBakerInfo(from: res, andDelegate: delegate)
					let _ = DiskService.write(encodable: res, toFileName: filename)
					
				} else {
					self?.updateBakerError(withDelegate: delegate)
				}
				
				completion(Result.success(true))
			}
		}
	}
	
	private func updateBakerInfo(from rewardObj: AggregateRewardInformation, andDelegate delegate: TzKTAccountDelegate) {
		bakerText = delegate.alias ?? delegate.address
		
		if let previousReward = rewardObj.previousReward {
			previousBakerIconURL = previousReward.bakerLogo
			previousBakerAmountTitle = "Amount (fee)"
			previousBakerAmount = previousReward.amount.normalisedRepresentation + " (\(previousReward.fee * 100)%)"
			previousBakerTimeTitle = "Time"
			previousBakerTime = previousReward.timeString
			previousBakerCycleTitle = "Cycle"
			previousBakerCycle = previousReward.cycle.description
			
		} else if let previousReward = rewardObj.estimatedPreviousReward {
			previousBakerIconURL = previousReward.bakerLogo
			previousBakerAmountTitle = "Est Amount (fee)"
			previousBakerAmount = previousReward.amount.normalisedRepresentation + " (\(previousReward.fee * 100)%)"
			previousBakerTimeTitle = "Est Time"
			previousBakerTime = previousReward.timeString
			previousBakerCycleTitle = "Est Cycle"
			previousBakerCycle = previousReward.cycle.description
		} else {
			previousBakerIconURL = nil
			previousBakerAmount = "N/A"
			previousBakerTime = "N/A"
			previousBakerCycle = "N/A"
		}
		
		if let nextReward = rewardObj.estimatedNextReward {
			nextBakerIconURL = nextReward.bakerLogo
			nextBakerAmount = nextReward.amount.normalisedRepresentation + " (\(nextReward.fee * 100)%)"
			nextBakerTime = nextReward.timeString
			nextBakerCycle = nextReward.cycle.description
		} else {
			nextBakerIconURL = nil
			nextBakerAmount = "N/A"
			nextBakerTime = "N/A"
			nextBakerCycle = "N/A"
		}
	}
	
	private func updateBakerError(withDelegate delegate: TzKTAccountDelegate?) {
		if let del = delegate {
			bakerText = del.alias ?? del.address
			
		} else {
			bakerText = ""
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
			return AllChartData(day: [], week: [], month: [], year: [])
		}
		
		let daySet = createDataSet(for: data.quotes15mNogaps)
		let weekSet = createDataSet(for: data.quotes1hNogaps)
		let monthSet = createDataSet(for: data.quotes1dNogaps)
		let yearSet = createDataSet(for: data.quotes1wNogaps)
		
		return AllChartData(day: daySet, week: weekSet, month: monthSet, year: yearSet)
	}
	
	func createDataSet(for data: CoinGeckoMarketDataResponse) -> [ChartViewDataPoint] {
		let updatedData = data.lessThan100Samples()
		
		var setData: [ChartViewDataPoint] = []
		for item in updatedData {
			let timestamp = item[0] / 1000
			let val = item[1]
			
			setData.append( ChartViewDataPoint(value: val, date: Date(timeIntervalSince1970: timestamp)) )
		}
		
		return setData
	}
	
	func createDataSet(for dataArray: [DipDupChartObject]) -> [ChartViewDataPoint] {
		var setData: [ChartViewDataPoint] = []
		for item in dataArray {
			let date = item.date() ?? Date()
			let val = item.averageDouble()
			
			setData.append( ChartViewDataPoint(value: val, date: date) )
		}
		
		return setData
	}
}
