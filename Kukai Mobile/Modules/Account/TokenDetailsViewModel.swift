//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import OSLog

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

struct LoadingData: Hashable, Identifiable {
	let id = UUID()
}

struct TokenDetailsHeaderData: Hashable, Identifiable {
	let id = UUID()
	var tokenURL: URL?
	var tokenImage: UIImage?
	var tokenName: String
	var fiatAmount: String
	var priceChangeText: String
	var isPriceChangePositive: Bool
	var priceRange: String
}

struct TokenDetailsButtonData: Hashable, Identifiable {
	let id = UUID()
	var isFavourited: Bool
	let canBeUnFavourited: Bool
	let isHidden: Bool
	let canBeHidden: Bool
	let canBePurchased: Bool
	let canBeViewedOnline: Bool
	let hasMoreButton: Bool
}

struct TokenDetailsBalanceData: Hashable, Identifiable {
	let id = UUID()
	let balance: String
	let value: String
	let availableBalance: String
	let availableValue: String
}

struct TokenDetailsSendData: Hashable {
	var isBuyTez: Bool
	var isDisabled: Bool
}

struct TokenDetailsBakerData: Hashable {
	let bakerIcon: URL?
	let bakerName: String?
	let bakerApy: Decimal
	let regularlyVotes: Bool
	let freeSpace: Decimal
	let enoughSpaceForBalance: Bool
}

struct TokenDetailsStakeData: Hashable {
	let stakedBalance: String
	let stakedValue: String
	let finalizeBalance: String
	let finalizeValue: String
	let canStake: Bool
	let canUnstake: Bool
	let canFinalize: Bool
}

struct TokenDetailsActivityHeader: Hashable, Identifiable {
	let id = UUID()
	let header: Bool
}

struct TokenDetailsMessageData: Hashable {
	let message: String
}



@objc protocol TokenDetailsViewModelDelegate: AnyObject {
	func setBakerTapped()
	func sendTapped()
	func stakingRewardsInfoTapped()
	func launchExternalBrowser(withURL url: URL)
}

public class TokenDetailsViewModel: ViewModel, TokenDetailsChartCellDelegate {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	private static var bakerRewardsCacheFilename: String {
		get {
			return "TokenDetailsViewModel-baker-rewards-xtz-\(DependencyManager.shared.selectedWalletAddress ?? "")"
		}
	}
	private var currentChartRange: TokenDetailsChartCellRange = .day
	private let chartDateFormatter = DateFormatter(withFormat: "MMM dd HH:mm a")
	private var initialChartLoad = true
	private var onlineXTZFetchGroup = DispatchGroup()
	
	// Set by VC
	weak var delegate: TokenDetailsViewModelDelegate? = nil
	
	var token: Token? = nil
	var tokenFiatPrice = ""
	var needsToLoadOnlineXTZData = false
	
	// Set by VM
	var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	weak var weakTokenHeaderCell: TokenDetailsHeaderCell? = nil
	var tokenHeaderData = TokenDetailsHeaderData(tokenURL: nil, tokenImage: UIImage.unknownToken(), tokenName: "", fiatAmount: "", priceChangeText: "", isPriceChangePositive: true, priceRange: "")
	var chartController = ChartHostingController()
	var chartData = AllChartData(day: [], week: [], month: [], year: [])
	var chartDataUnsucessful = false
	var buttonData: TokenDetailsButtonData? = nil
	var balanceData: TokenDetailsBalanceData? = nil
	var sendData = TokenDetailsSendData(isBuyTez: false, isDisabled: false)
	var bakerData: TokenDetailsBakerData? = nil
	var stakeData: TokenDetailsStakeData? = nil
	var onlineDataLoading = LoadingData()
	var rewardData: AggregateRewardInformation? = nil
	var activityHeaderData = TokenDetailsActivityHeader(header: true)
	var activityFooterData = TokenDetailsActivityHeader(header: false)
	var activityItems: [TzKTTransactionGroup] = []
	var noItemsData = TokenDetailsMessageData(message: "No items avaialble at this time, check again later")
	
	
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "TokenDetailsChartCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsChartCell")
		tableView.register(UINib(nibName: "TokenDetailsBalanceCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsBalanceCell")
		tableView.register(UINib(nibName: "TokenDetailsSendCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsSendCell")
		tableView.register(UINib(nibName: "TokenDetailsBakerCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsBakerCell")
		tableView.register(UINib(nibName: "TokenDetailsStakeBalanceCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsStakeBalanceCell")
		tableView.register(UINib(nibName: "TokenDetailsStakingRewardsCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsStakingRewardsCell")
		tableView.register(UINib(nibName: "TokenDetailsActivityHeaderCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsActivityHeaderCell")
		tableView.register(UINib(nibName: "TokenDetailsActivityHeaderCell_footer", bundle: nil), forCellReuseIdentifier: "TokenDetailsActivityHeaderCell_footer")
		tableView.register(UINib(nibName: "TokenDetailsLoadingCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsLoadingCell")
		tableView.register(UINib(nibName: "TokenDetailsMessageCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsMessageCell")
		
		tableView.register(UINib(nibName: "ActivityItemCell", bundle: nil), forCellReuseIdentifier: "ActivityItemCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			let weakSelf = self
			
			guard let self = self else { return UITableViewCell() }
			
			if let obj = item.base as? TokenDetailsHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsHeaderCell") as? TokenDetailsHeaderCell {
				weakTokenHeaderCell = cell
				cell.setup(data: obj)
				return cell
				
			} else if let _ = item.base as? AllChartData, self.initialChartLoad == true, self.chartDataUnsucessful == false, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				cell.setup()
				return cell
				
			} else if let obj = item.base as? AllChartData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				self.chartController.setDelegate(weakSelf)
				cell.setup(delegate: self, chartController: self.chartController, allChartData: obj)
				return cell
				
			} else if let obj = item.base as? TokenDetailsBalanceData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsBalanceCell", for: indexPath) as? TokenDetailsBalanceCell {
				if let tokenURL = self.tokenHeaderData.tokenURL {
					MediaProxyService.load(url: tokenURL, to: cell.tokenIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
					
				} else {
					cell.tokenIcon.image = self.tokenHeaderData.tokenImage
				}
				
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item.base as? TokenDetailsSendData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsSendCell", for: indexPath) as? TokenDetailsSendCell {
				cell.sendButton?.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.sendTapped), for: .touchUpInside)
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item.base as? TokenDetailsBakerData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsBakerCell", for: indexPath) as? TokenDetailsBakerCell {
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item.base as? TokenDetailsStakeData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakeBalanceCell", for: indexPath) as? TokenDetailsStakeBalanceCell {
				cell.setup(data: obj)
				return cell
				
			} else if let _ = item.base as? LoadingData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsLoadingCell", for: indexPath) as? TokenDetailsLoadingCell {
				cell.setup()
				return cell
				
			} else if let obj = item.base as? AggregateRewardInformation, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakingRewardsCell", for: indexPath) as? TokenDetailsStakingRewardsCell {
				cell.infoButton.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.stakingRewardsInfoTapped), for: .touchUpInside)
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item.base as? TokenDetailsActivityHeader, obj.header == true, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let _ = item.base as? TokenDetailsActivityHeader, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell_footer", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let obj = item.base as? TokenDetailsMessageData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsMessageCell", for: indexPath) as? TokenDetailsMessageCell {
				cell.messageLabel.text = obj.message
				return cell
				
			} else if let obj = item.base as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
				cell.setup(data: obj)
				return cell
			}
			
			let backupCell = UITableViewCell()
			backupCell.backgroundColor = .clear
			
			return backupCell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let token = self.token else {
			return
		}
		
		// Load instantly
		// - token header
		// - chart spinner
		// - balance / available balance
		// - Send button
		// - if xtz, spinner
		// - else, load activity
		
		loadOfflineData(token: token)
		sendData.isBuyTez = (token.isXTZ() && token.balance == .zero())
		sendData.isDisabled = DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false
		
		var data: [AnyHashableSendable] = [
			.init(tokenHeaderData),
			.init(chartData),
			.init(balanceData),
			.init(sendData)
		]
		
		if token.isXTZ() {
			
			// If XTZ and we have a delegate set, then we need to fetch more data before displaying anything else
			// Otherwise load the baker onboarding flow
			if DependencyManager.shared.balanceService.account.delegate != nil {
				self.needsToLoadOnlineXTZData = true
				data.append(.init(onlineDataLoading))
			} else {
				data.append(.init(TokenDetailsBakerData(bakerIcon: nil, bakerName: nil, bakerApy: 0, regularlyVotes: false, freeSpace: 0, enoughSpaceForBalance: false) ))
			}
		} else {
			
			// If its not XTZ, then load the activity items (if any) and move on
			data.append(contentsOf: loadActivitySection(token: token))
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		currentSnapshot.appendSections([0])
		currentSnapshot.appendItems(data, toSection: 0)
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		self.state = .success(nil)
		
		
		
		// When done
		// - kick off chart data fetch
		//    - replace chart cell when done
		// - if xtz, kick off baker, baker rewards, + any other stake data fetch
		//    - add baker view
		//    - add stake view
		//    - add pending unstake view
		// 	  - add rewards view
		//    - add activity
		
		
		// Fetch any required remote data
		loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			self.initialChartLoad = false
			
			switch result {
				case .success(let data):
					self.currentSnapshot.deleteItems([.init(self.chartData)])
					self.chartData = data
					self.currentSnapshot.insertItems([.init(self.chartData)], afterItem: .init(self.tokenHeaderData))
					
					self.calculatePriceChange(point: nil)
					self.weakTokenHeaderCell?.changePriceDisplay(data: self.tokenHeaderData)
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
					
				case .failure(_):
					self.currentSnapshot.deleteItems([.init(self.chartData)])
					self.chartDataUnsucessful = true
					self.chartData = AllChartData(day: [], week: [], month: [], year: [])
					self.currentSnapshot.insertItems([.init(self.chartData)], afterItem: .init(self.tokenHeaderData))
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
			}
		}
		
		if self.needsToLoadOnlineXTZData {
			loadOnlineXTZData(token: token) { [weak self] in
				guard let self = self else { return }
				
				self.currentSnapshot.deleteItems([.init(self.onlineDataLoading)])
				
				var newData: [AnyHashableSendable] = [.init(self.bakerData), .init(self.stakeData)]
				/*
				 pending unstake
				 */
				
				if let rewardData = rewardData {
					newData.append(.init(rewardData))
				}
				
				newData.append(contentsOf: loadActivitySection(token: token))
				self.currentSnapshot.insertItems(newData, afterItem: .init(self.sendData))
				
				ds.apply(self.currentSnapshot, animatingDifferences: true)
				self.state = .success(nil)
			}
		}
	}
	
	
	
	// MARK: - Data
	
	public static func deleteAllCachedData() {
		let _ = DiskService.delete(fileName: TokenDetailsViewModel.bakerRewardsCacheFilename)
	}
	
	func loadOfflineData(token: Token) {
		self.token = token
		self.tokenHeaderData.tokenName = token.symbol
		
		let tokenBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.balance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		let availableTokenBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.availableBalance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		
		if token.isXTZ() {
			self.tokenHeaderData.tokenImage = UIImage.tezosToken()
			self.tokenHeaderData.tokenName = "XTZ"
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			self.tokenHeaderData.fiatAmount = tokenFiatPrice
			
			let xtzValue = token.balance * fiatPerToken
			let tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			let availableXtzValue = token.availableBalance * fiatPerToken
			let availableValue = DependencyManager.shared.coinGeckoService.format(decimal: availableXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			buttonData = TokenDetailsButtonData(isFavourited: true, canBeUnFavourited: false, isHidden: false, canBeHidden: false, canBePurchased: true, canBeViewedOnline: false, hasMoreButton: false)
			balanceData = TokenDetailsBalanceData(balance: tokenBalance, value: tokenValue, availableBalance: availableTokenBalance, availableValue: availableValue)
			
		} else {
			self.tokenHeaderData.tokenURL = token.thumbnailURL
			self.tokenHeaderData.tokenName = token.symbol
			
			let isFav = token.isFavourite
			let isHidden = token.isHidden
			buttonData = TokenDetailsButtonData(isFavourited: isFav, canBeUnFavourited: true, isHidden: isHidden, canBeHidden: true, canBePurchased: false, canBeViewedOnline: true, hasMoreButton: true)
			
			if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
				var tokenPriceString = ""
				let fiatPerToken = (tokenValueAndRate.marketRate * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ)
				if fiatPerToken < 0.000001 {
					tokenPriceString = "<\(DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2))"
					
				} else if fiatPerToken < 0.01 {
					tokenPriceString = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 6)
					
				} else {
					tokenPriceString = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
				}
				
				tokenFiatPrice = tokenPriceString
				tokenHeaderData.fiatAmount = tokenFiatPrice
				
				
				var tokenBalanceValueString = ""
				let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
				if xtzPrice < 0.000001 {
					tokenBalanceValueString = "<\(DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2))"
					
				} else if xtzPrice < 0.01 {
					tokenBalanceValueString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 6)
					
				} else {
					tokenBalanceValueString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
				}
				
				balanceData = TokenDetailsBalanceData(balance: tokenBalance, value: tokenBalanceValueString, availableBalance: tokenBalance, availableValue: tokenBalanceValueString)
				
			} else {
				let dashedString = DependencyManager.shared.coinGeckoService.dashedCurrencyString()
				tokenHeaderData.fiatAmount = dashedString
				balanceData = TokenDetailsBalanceData(balance: tokenBalance, value: dashedString, availableBalance: tokenBalance, availableValue: dashedString)
			}
		}
	}
	
	func loadActivitySection(token: Token) -> [AnyHashableSendable] {
		var data: [AnyHashableSendable] = [.init(activityHeaderData)]
		self.activityItems = DependencyManager.shared.activityService.filterSendReceive(forToken: token, count: 5)
		
		if activityItems.count == 0 {
			data.append(.init(self.noItemsData))
			
		} else {
			data.append(contentsOf: activityItems.map({ .init($0) }))
			data.append(.init(self.activityFooterData))
		}
		
		return data
	}
	
	func loadOnlineXTZData(token: Token, completion: @escaping (() -> Void)) {
		guard let delegate = DependencyManager.shared.balanceService.account.delegate else {
			completion()
			return
		}
		
		let account = DependencyManager.shared.balanceService.account
		let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
		
		// TODO: fetch baker icon
		// TODO: need to fetch bakerAPy
		// TODO: need to fetch regularlyVotes
		// TODO: need to fetch free space
		let bakerString = (account.delegate?.alias ?? account.delegate?.address.truncateTezosAddress() ?? "") + "  "
		bakerData = TokenDetailsBakerData(bakerIcon: nil, bakerName: bakerString, bakerApy: 0, regularlyVotes: true, freeSpace: 1000, enoughSpaceForBalance: true)
		
		
		let stakeBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.stakedBalance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		let stakeXtzValue = (token.stakedBalance as? XTZAmount ?? .zero()) * fiatPerToken
		let stakeValue = DependencyManager.shared.coinGeckoService.format(decimal: stakeXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
		
		let unstakeBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.unstakedBalance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		let unstakeXtzValue = (token.unstakedBalance as? XTZAmount ?? .zero()) * fiatPerToken
		let unstakeValue = DependencyManager.shared.coinGeckoService.format(decimal: unstakeXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
		
		// TODO: only do this if relevant
		// TODO: come up with logic to dictate if can stake (e.g. is free space, user has more than 1 XTZ, etc)
		let canStake = true // is delegate and has funds
		let canUnstake = token.stakedBalance > .zero()
		let canFinalize = token.unstakedBalance > .zero()
		
		stakeData = TokenDetailsStakeData(stakedBalance: stakeBalance, stakedValue: stakeValue, finalizeBalance: unstakeBalance, finalizeValue: unstakeValue, canStake: canStake, canUnstake: canUnstake, canFinalize: canFinalize)
		
		
		
		
			
		// Get fresh baker data, as rewards are cached for an entire cycle and free space could change very regularly
		onlineXTZFetchGroup.enter()
		
		
		onlineXTZFetchGroup.leave()
		
		
		// Get rewards data from cache or remote
		if DependencyManager.shared.currentNetworkType != .ghostnet {
			onlineXTZFetchGroup.enter()
			
			if let bakerRewardCache = DiskService.read(type: AggregateRewardInformation.self, fromFileName: TokenDetailsViewModel.bakerRewardsCacheFilename), !bakerRewardCache.isOutOfDate(), !bakerRewardCache.moreThan1CycleBetweenPreiousAndNext() {
				self.rewardData = bakerRewardCache
				onlineXTZFetchGroup.leave()
				
			} else {
				DependencyManager.shared.tzktClient.estimateLastAndNextReward(forAddress: account.walletAddress, delegate: delegate) { [weak self] result in
					if let res = try? result.get() {
						let _ = DiskService.write(encodable: res, toFileName: TokenDetailsViewModel.bakerRewardsCacheFilename)
						self?.rewardData = res
						
					} else {
						Logger.app.error("Error fetching baker data: \(result.getFailure())")
					}
					
					self?.onlineXTZFetchGroup.leave()
				}
			}
		}
			
		
		
		// Fire completion when everything is done
		onlineXTZFetchGroup.notify(queue: .global(qos: .background)) {
			completion()
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
		let currencyMultiplier = (DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ as NSDecimalNumber).doubleValue
		var setData: [ChartViewDataPoint] = []
		
		for item in dataArray {
			let date = item.date() ?? Date()
			let val = item.averageDouble() * currencyMultiplier
			
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
			
			self.tokenHeaderData.priceChangeText = "\(abs(percentage))%"
			self.tokenHeaderData.isPriceChangePositive = dataPoint.value > first.value
			self.tokenHeaderData.priceRange = (point == nil) ? "Today" : chartDateFormatter.string(from: dataPoint.date)
			
		} else {
			self.tokenHeaderData.priceChangeText = ""
			self.tokenHeaderData.isPriceChangePositive = false
			self.tokenHeaderData.priceRange = ""
		}
	}
	
	func chartRangeChanged(to: TokenDetailsChartCellRange) {
		currentChartRange = to
	}
}



// MARK: - ChartHostingControllerDelegate

extension TokenDetailsViewModel: ChartHostingControllerDelegate {
	
	func didSelectPoint(_ point: ChartViewDataPoint?, ofIndex: Int) {
		self.calculatePriceChange(point: point)
		
		self.tokenHeaderData.fiatAmount = DependencyManager.shared.coinGeckoService.format(decimal: Decimal(point?.value ?? 0), numberStyle: .currency, maximumFractionDigits: 2)
		self.weakTokenHeaderCell?.changePriceDisplay(data: tokenHeaderData)
	}
	
	func didFinishSelectingPoint() {
		self.calculatePriceChange(point: nil)
		
		self.tokenHeaderData.fiatAmount = self.tokenFiatPrice
		self.weakTokenHeaderCell?.changePriceDisplay(data: tokenHeaderData)
	}
}
