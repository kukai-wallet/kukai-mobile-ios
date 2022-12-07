//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift

struct AllChartData: Hashable {
	let id = UUID()
	let day: [ChartViewDataPoint]
	let week: [ChartViewDataPoint]
	let month: [ChartViewDataPoint]
	let year: [ChartViewDataPoint]
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct LoadingData: Hashable {
	let id = UUID()
}

struct TokenDetailsButtonData: Hashable {
	var isFavourited: Bool
	let canBeUnFavourited: Bool
	let isHidden: Bool
	let canBeHidden: Bool
	let canBePurchased: Bool
	let canBeViewedOnline: Bool
	let hasMoreButton: Bool
}

struct TokenDetailsBalanceAndBakerData: Hashable {
	let balance: String
	let value: String
	let isStakingPossible: Bool
	let isStaked: Bool
	let bakerName: String
}

struct TokenDetailsSendData: Hashable {
	var isBuyTez: Bool
}

struct TokenDetailsActivityHeader: Hashable {
	let header: Bool
}

struct TokenDetailsMessageData: Hashable {
	let message: String
}



protocol TokenDetailsViewModelDelegate: AnyObject {
	func moreMenu() -> UIMenu
}

public class TokenDetailsViewModel: ViewModel, TokenDetailsChartCellDelegate {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private let bakerRewardsCacheFilename = "TokenDetailsViewModel-baker-rewards-xtz"
	private var currentChartRange: TokenDetailsChartCellRange = .day
	private let chartDateFormatter = DateFormatter(withFormat: "MMM dd HH:mm a")
	
	// Set by VC
	weak var delegate: TokenDetailsViewModelDelegate? = nil
	weak var chartDelegate: ChartHostingControllerDelegate? = nil
	var token: Token? = nil
	var buttonDelegate: TokenDetailsButtonsCellDelegate? = nil
	
	// Set by VM
	var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	var tokenIcon: UIImage? = nil
	var tokenIconURL: URL? = nil
	var tokenSymbol = ""
	var tokenFiatPrice = ""
	var tokenPriceChange = ""
	var tokenPriceChangeIsUp = false
	var tokenPriceDateText = ""
	
	var chartController = ChartHostingController()
	var chartData = AllChartData(day: [], week: [], month: [], year: [])
	var buttonData: TokenDetailsButtonData? = nil
	var balanceAndBakerData: TokenDetailsBalanceAndBakerData? = nil
	var sendData = TokenDetailsSendData(isBuyTez: false)
	var stakingRewardLoadingData = LoadingData()
	var stakingRewardData: AggregateRewardInformation? = nil
	var activityHeaderData = TokenDetailsActivityHeader(header: true)
	var activityLoadingData = LoadingData()
	var activityFooterData = TokenDetailsActivityHeader(header: false)
	var activityItems: [TzKTTransactionGroup] = []
	var noItemsData = TokenDetailsMessageData(message: "No items avaialble at this time, check again later")
	
	
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let obj = item as? AllChartData, obj.day.count == 0, obj.week.count == 0, obj.month.count == 0, obj.year.count == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				cell.setup()
				return cell
				
			} else if let obj = item as? AllChartData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				self.chartController.setDelegate(self.chartDelegate)
				cell.setup(delegate: self, chartController: self.chartController, allChartData: obj)
				return cell
				
			} else if let obj = item as? TokenDetailsButtonData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsButtonsCell", for: indexPath) as? TokenDetailsButtonsCell {
				cell.setup(buttonData: obj, moreMenu: self.delegate?.moreMenu(), delegate: self.buttonDelegate)
				return cell
				
			} else if let obj = item as? TokenDetailsBalanceAndBakerData {
				let reuse = obj.isStakingPossible ? (obj.isStaked ? "TokenDetailsBalanceAndBakerCell_baker" : "TokenDetailsBalanceAndBakerCell_nobaker") : "TokenDetailsBalanceAndBakerCell_nostaking"
				
				if let cell = tableView.dequeueReusableCell(withIdentifier: reuse, for: indexPath) as? TokenDetailsBalanceAndBakerCell {
					
					if let tokenURL = self.tokenIconURL {
						MediaProxyService.load(url: tokenURL, to: cell.tokenIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.tokenIcon.frame.size)
						
					} else {
						cell.tokenIcon.image = self.tokenIcon
					}
					cell.setup(data: obj)
					
					return cell
				}
			} else if let obj = item as? TokenDetailsSendData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsSendCell", for: indexPath) as? TokenDetailsSendCell {
				cell.setup(data: obj)
				return cell
				
			} else if let _ = item as? LoadingData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsLoadingCell", for: indexPath) as? TokenDetailsLoadingCell {
				cell.setup()
				return cell
				
			} else if let obj = item as? AggregateRewardInformation, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakingRewardsCell", for: indexPath) as? TokenDetailsStakingRewardsCell {
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item as? TokenDetailsActivityHeader, obj.header == true, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let _ = item as? TokenDetailsActivityHeader, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell_footer", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let obj = item as? TokenDetailsMessageData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsMessageCell", for: indexPath) as? TokenDetailsMessageCell {
				cell.messageLabel.text = obj.message
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityItemCell", for: indexPath) as? TokenDetailsActivityItemCell {
				cell.setup(data: obj)
				return cell
				
			}
			
			return UITableViewCell()
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let token = self.token else {
			return
		}
		
		loadTokenData(token: token)
		sendData.isBuyTez = (token.isXTZ() && token.balance == .zero())
		
		var data: [AnyHashable] = [
			chartData,
			buttonData,
			balanceAndBakerData,
			sendData
		]
		
		if balanceAndBakerData?.isStakingPossible == true && balanceAndBakerData?.isStaked == true {
			data.append(stakingRewardLoadingData)
		}
		
		let initialActivitySection: [AnyHashable] = [activityHeaderData, activityLoadingData, activityFooterData]
		data.append(contentsOf: initialActivitySection)
		
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections([0])
		currentSnapshot.appendItems(data, toSection: 0)
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		self.state = .success(nil)
		
		
		// Trigger remote data fetching
		loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.currentSnapshot.deleteItems([self.chartData])
					self.chartData = data
					self.currentSnapshot.insertItems([self.chartData], beforeItem: self.buttonData)
					
					self.calculatePriceChange(point: nil)
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
					
				case .failure(let error):
					self.state = .failure(error, "Unable to get chart data")
			}
		}
		
		loadBakerData { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.currentSnapshot.deleteItems([self.stakingRewardLoadingData])
					self.stakingRewardData = data
					self.currentSnapshot.insertItems([data], afterItem: self.sendData)
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					
				case .failure(let error):
					self.state = .failure(error, "Unable to get chart data")
			}
		}
		
		loadActivityData { [weak self] result in
			guard let self = self else { return }
			
			switch result {
				case .success(let data):
					self.currentSnapshot.deleteItems([self.activityLoadingData])
					self.activityItems = data
					
					if data.count == 0 {
						self.currentSnapshot.insertItems([self.noItemsData], afterItem: self.activityHeaderData)
						
					} else {
						self.currentSnapshot.insertItems(data, afterItem: self.activityHeaderData)
					}
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					
				case .failure(let error):
					self.state = .failure(error, "Unable to get chart data")
			}
		}
	}
	
	
	
	// MARK: - Data
	
	func loadTokenData(token: Token) {
		self.token = token
		tokenSymbol = token.symbol
		
		let tokenBalance = token.balance.normalisedRepresentation
		
		if token.isXTZ() {
			tokenIcon = UIImage(named: "tezos-logo")
			tokenSymbol = "Tezos"
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			
			let account = DependencyManager.shared.balanceService.account
			let xtzValue = (token.balance as? XTZAmount ?? .zero()) * fiatPerToken
			let tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			buttonData = TokenDetailsButtonData(isFavourited: true, canBeUnFavourited: false, isHidden: false, canBeHidden: false, canBePurchased: true, canBeViewedOnline: false, hasMoreButton: false)
			balanceAndBakerData = TokenDetailsBalanceAndBakerData(balance: tokenBalance, value: tokenValue, isStakingPossible: true, isStaked: (account.delegate != nil), bakerName: account.delegate?.alias ?? account.delegate?.address ?? "")
			
		} else if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
			tokenIconURL = token.thumbnailURL
			tokenSymbol = token.symbol
			
			let fiatPerToken = tokenValueAndRate.marketRate
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			
			let isFav = TokenStateService.shared.isFavourite(token: token).isFavourite
			let isHidden = TokenStateService.shared.isHidden(token: token)
			let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			let tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
			
			buttonData = TokenDetailsButtonData(isFavourited: isFav, canBeUnFavourited: true, isHidden: isHidden, canBeHidden: true, canBePurchased: false, canBeViewedOnline: true, hasMoreButton: true)
			balanceAndBakerData = TokenDetailsBalanceAndBakerData(balance: tokenBalance, value: tokenValue, isStakingPossible: false, isStaked: false, bakerName: "")
		}
	}
	
	func loadBakerData(completion: @escaping ((Result<AggregateRewardInformation, KukaiError>) -> Void)) {
		let account = DependencyManager.shared.balanceService.account
		guard let delegate = account.delegate else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find baker details")))
			return
		}
		
		if let bakerRewardCache = DiskService.read(type: AggregateRewardInformation.self, fromFileName: bakerRewardsCacheFilename), !bakerRewardCache.isOutOfDate(), !bakerRewardCache.moreThan1CycleBetweenPreiousAndNext() {
			completion(Result.success(bakerRewardCache))
			
		} else {
			DependencyManager.shared.tzktClient.estimateLastAndNextReward(forAddress: account.walletAddress, delegate: delegate) { [weak self] result in
				if let res = try? result.get(), let filename = self?.bakerRewardsCacheFilename {
					let _ = DiskService.write(encodable: res, toFileName: filename)
					completion(Result.success(res))
					
				} else {
					completion(Result.failure(result.getFailure()))
				}
			}
		}
	}
	
	func loadActivityData(completion: @escaping ((Result<[TzKTTransactionGroup], KukaiError>) -> Void)) {
		guard let wallet = DependencyManager.shared.selectedWallet?.address else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find wallet")))
			return
		}
		
		DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: wallet, refreshType: .refreshIfCacheEmpty) { [weak self] error in
			if let err = error {
				completion(Result.failure(err))
				return
			}
			
			if let t = self?.token {
				let items = DependencyManager.shared.activityService.filterSendReceive(forToken: t, count: 5)
				completion(Result.success(items))
				return
			}
			
			completion(Result.failure(KukaiError.unknown(withString: "Can't find token for activity")))
		}
	}
	
	
	// MARK: - Chart
	
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
	
	func calculatePriceChange(point: ChartViewDataPoint?) {
		var dataSet: [ChartViewDataPoint] = []
		var dataPoint = point
		
		switch currentChartRange {
			case .day:
				dataSet = chartData.day
			case .week:
				dataSet = chartData.week
			case .month:
				dataSet = chartData.month
			case .year:
				dataSet = chartData.year
		}
		
		if dataPoint == nil {
			dataPoint = dataSet.last
		}
		
		if dataSet.count > 1, let first = dataSet.first, let dataPoint = dataPoint {
			let difference = first.value - dataPoint.value
			let percentage = Decimal(difference / first.value).rounded(scale: 2, roundingMode: .bankers)
			
			tokenPriceChange = "\(abs(percentage))%"
			tokenPriceChangeIsUp = dataPoint.value > first.value
			tokenPriceDateText = (point == nil) ? "Today" : chartDateFormatter.string(from: dataPoint.date)
			
		} else {
			tokenPriceChange = ""
			tokenPriceChangeIsUp = false
			tokenPriceDateText = ""
		}
	}
	
	func chartRangeChanged(to: TokenDetailsChartCellRange) {
		currentChartRange = to
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*
	private let bakerRewardsCacheFilename = "TokenDetailsViewModel-baker-rewards-xtz"
	
	var token: Token? = nil
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
	var tokenCanBeViewedOnline = false
	var tokenHasMoreButton = false
	
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
	
	var activityAvailable = false
	var activityItems: [TzKTTransactionGroup] = []
	
	
	
	func loadTokenData(token: Token) {
		self.token = token
		tokenSymbol = token.symbol
		tokenBalance = token.balance.normalisedRepresentation + " \(token.symbol)"
		
		if token.isXTZ() {
			tokenIcon = UIImage(named: "tezos-logo")
			tokenSymbol = "Tezos"
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			
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
			tokenSymbol = token.symbol
			
			let fiatPerToken = tokenValueAndRate.marketRate
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			
			tokenIsFavourited = TokenStateService.shared.isFavourite(token: token).isFavourite
			tokenCanBeUnFavourited = true
			tokenIsHidden = TokenStateService.shared.isHidden(token: token)
			tokenCanBeHidden = true
			tokenCanBePurchased = false
			tokenCanBeViewedOnline = true
			tokenHasMoreButton = true
			
			let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
			
			isStakingPossible = false
			self.state = .success(nil)
		}
	}
	
	
	
	// MARK: - Baker / Rewards
	
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
	
	
	
	// MARK: - Chart
	
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
	
	func calculatePriceChange(data: AllChartData) {
		if data.day.count > 1, let first = data.day.first, let last = data.day.last {
			let difference = first.value - last.value
			let percentage = Decimal(difference / first.value).rounded(scale: 2, roundingMode: .bankers)
			
			tokenPriceChange = "\(percentage)%"
			tokenPriceChangeIsUp = last.value > first.value
			tokenPriceDateText = "Today"
			
		} else {
			tokenPriceChange = ""
			tokenPriceChangeIsUp = false
			tokenPriceDateText = ""
		}
	}
	
	
	
	// MARK: - Activity
	
	func loadActivityData(completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		guard let wallet = DependencyManager.shared.selectedWallet?.address else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find wallet")))
			return
		}
		
		DependencyManager.shared.activityService.fetchTransactionGroups(forAddress: wallet, refreshType: .refreshIfCacheEmpty) { [weak self] error in
			if let err = error {
				self?.activityAvailable = false
				completion(Result.failure(err))
				return
			}
			
			if let t = self?.token {
				self?.activityItems = DependencyManager.shared.activityService.filterSendReceive(forToken: t)
				
				if (self?.activityItems.count ?? 0) > 0 {
					self?.activityAvailable = true
				}
				
				completion(Result.success(true))
				return
			}
			
			completion(Result.failure(KukaiError.unknown(withString: "Can't find token for activity")))
		}
	}
	*/
}
