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

struct TokenDetailsBalanceAndBakerData: Hashable, Identifiable {
	let id = UUID()
	let balance: String
	let value: String
	let isStakingPossible: Bool
	let isStaked: Bool
	let bakerName: String
}

struct TokenDetailsSendData: Hashable {
	var isBuyTez: Bool
	var isDisabled: Bool
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
	typealias CellDataType = AnyHashable
	
	private static let bakerRewardsCacheFilename = "TokenDetailsViewModel-baker-rewards-xtz"
	private var currentChartRange: TokenDetailsChartCellRange = .day
	private let chartDateFormatter = DateFormatter(withFormat: "MMM dd HH:mm a")
	private var initialChartLoad = true
	
	// Set by VC
	weak var delegate: TokenDetailsViewModelDelegate? = nil
	
	var token: Token? = nil
	var tokenFiatPrice = ""
	
	// Set by VM
	var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	weak var weakTokenHeaderCell: TokenDetailsHeaderCell? = nil
	var tokenHeaderData = TokenDetailsHeaderData(tokenURL: nil, tokenImage: UIImage.unknownToken(), tokenName: "", fiatAmount: "", priceChangeText: "", isPriceChangePositive: true, priceRange: "")
	var chartController = ChartHostingController()
	var chartData = AllChartData(day: [], week: [], month: [], year: [])
	var chartDataUnsucessful = false
	var buttonData: TokenDetailsButtonData? = nil
	var balanceAndBakerData: TokenDetailsBalanceAndBakerData? = nil
	var sendData = TokenDetailsSendData(isBuyTez: false, isDisabled: false)
	var stakingRewardLoadingData = LoadingData()
	var stakingRewardData: AggregateRewardInformation? = nil
	var activityHeaderData = TokenDetailsActivityHeader(header: true)
	var activityFooterData = TokenDetailsActivityHeader(header: false)
	var activityItems: [TzKTTransactionGroup] = []
	var noItemsData = TokenDetailsMessageData(message: "No items avaialble at this time, check again later")
	
	
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "TokenDetailsChartCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsChartCell")
		tableView.register(UINib(nibName: "TokenDetailsBalanceAndBakerCell_baker", bundle: nil), forCellReuseIdentifier: "TokenDetailsBalanceAndBakerCell_baker")
		tableView.register(UINib(nibName: "TokenDetailsBalanceAndBakerCell_nobaker", bundle: nil), forCellReuseIdentifier: "TokenDetailsBalanceAndBakerCell_nobaker")
		tableView.register(UINib(nibName: "TokenDetailsBalanceAndBakerCell_nostaking", bundle: nil), forCellReuseIdentifier: "TokenDetailsBalanceAndBakerCell_nostaking")
		tableView.register(UINib(nibName: "TokenDetailsSendCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsSendCell")
		tableView.register(UINib(nibName: "TokenDetailsStakingRewardsCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsStakingRewardsCell")
		tableView.register(UINib(nibName: "TokenDetailsActivityHeaderCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsActivityHeaderCell")
		tableView.register(UINib(nibName: "TokenDetailsActivityHeaderCell_footer", bundle: nil), forCellReuseIdentifier: "TokenDetailsActivityHeaderCell_footer")
		tableView.register(UINib(nibName: "TokenDetailsLoadingCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsLoadingCell")
		tableView.register(UINib(nibName: "TokenDetailsMessageCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsMessageCell")
		
		tableView.register(UINib(nibName: "ActivityItemCell", bundle: nil), forCellReuseIdentifier: "ActivityItemCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			let weakSelf = self
			
			guard let self = self else { return UITableViewCell() }
			
			if let obj = item as? TokenDetailsHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsHeaderCell") as? TokenDetailsHeaderCell {
				weakTokenHeaderCell = cell
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item as? AllChartData, self.initialChartLoad == true, self.chartDataUnsucessful == false, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				cell.setup()
				return cell
				
			} else if let obj = item as? AllChartData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsChartCell", for: indexPath) as? TokenDetailsChartCell {
				self.chartController.setDelegate(weakSelf)
				cell.setup(delegate: self, chartController: self.chartController, allChartData: obj)
				return cell
				
			} else if let obj = item as? TokenDetailsBalanceAndBakerData {
				let reuse = obj.isStakingPossible ? (obj.isStaked ? "TokenDetailsBalanceAndBakerCell_baker" : "TokenDetailsBalanceAndBakerCell_nobaker") : "TokenDetailsBalanceAndBakerCell_nostaking"
				
				if let cell = tableView.dequeueReusableCell(withIdentifier: reuse, for: indexPath) as? TokenDetailsBalanceAndBakerCell {
					
					if let tokenURL = self.tokenHeaderData.tokenURL {
						MediaProxyService.load(url: tokenURL, to: cell.tokenIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
						
					} else {
						cell.tokenIcon.image = self.tokenHeaderData.tokenImage
					}
					
					if DependencyManager.shared.selectedWalletMetadata?.isWatchOnly == false {
						cell.bakerButton?.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.setBakerTapped), for: .touchUpInside)
					}
					cell.setup(data: obj)
					
					return cell
				}
			} else if let obj = item as? TokenDetailsSendData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsSendCell", for: indexPath) as? TokenDetailsSendCell {
				cell.sendButton?.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.sendTapped), for: .touchUpInside)
				cell.setup(data: obj)
				return cell
				
			} else if let _ = item as? LoadingData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsLoadingCell", for: indexPath) as? TokenDetailsLoadingCell {
				cell.setup()
				return cell
				
			} else if let obj = item as? AggregateRewardInformation, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakingRewardsCell", for: indexPath) as? TokenDetailsStakingRewardsCell {
				cell.infoButton.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.stakingRewardsInfoTapped), for: .touchUpInside)
				cell.setup(data: obj)
				return cell
				
			} else if let obj = item as? TokenDetailsActivityHeader, obj.header == true, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let _ = item as? TokenDetailsActivityHeader, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsActivityHeaderCell_footer", for: indexPath) as? TokenDetailsActivityHeaderCell {
				return cell
				
			} else if let obj = item as? TokenDetailsMessageData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsMessageCell", for: indexPath) as? TokenDetailsMessageCell {
				cell.messageLabel.text = obj.message
				return cell
				
			} else if let obj = item as? TzKTTransactionGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityItemCell", for: indexPath) as? ActivityItemCell {
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
		
		loadTokenData(token: token)
		sendData.isBuyTez = (token.isXTZ() && token.balance == .zero())
		sendData.isDisabled = DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false
		
		var data: [AnyHashable] = [
			tokenHeaderData,
			chartData,
			balanceAndBakerData,
			sendData
		]
		
		// TODO: remove testnet check in future when remote serivce supports ghostnet
		if balanceAndBakerData?.isStakingPossible == true && balanceAndBakerData?.isStaked == true && DependencyManager.shared.currentNetworkType != .testnet {
			data.append(stakingRewardLoadingData)
		}
		
		
		
		// Activity data gets loaded as part of token balances
		var activitySection: [AnyHashable] = [activityHeaderData]
		self.activityItems = DependencyManager.shared.activityService.filterSendReceive(forToken: token, count: 5)
		if activityItems.count == 0 {
			activitySection.append(self.noItemsData)
			
		} else {
			activitySection.append(contentsOf: activityItems)
			activitySection.append(self.activityFooterData)
		}
		data.append(contentsOf: activitySection)
		
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections([0])
		currentSnapshot.appendItems(data, toSection: 0)
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		self.state = .success(nil)
		
		
		// Trigger remote data fetching
		loadChartData(token: token) { [weak self] result in
			guard let self = self else { return }
			self.initialChartLoad = false
			
			switch result {
				case .success(let data):
					self.currentSnapshot.deleteItems([self.chartData])
					self.chartData = data
					self.currentSnapshot.insertItems([self.chartData], afterItem: self.tokenHeaderData)
					
					self.calculatePriceChange(point: nil)
					self.weakTokenHeaderCell?.changePriceDisplay(data: self.tokenHeaderData)
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
					
				case .failure(_):
					self.currentSnapshot.deleteItems([self.chartData])
					self.chartDataUnsucessful = true
					self.chartData = AllChartData(day: [], week: [], month: [], year: [])
					self.currentSnapshot.insertItems([self.chartData], afterItem: self.tokenHeaderData)
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
			}
		}
		 
		// TODO: remove testnet check in future when remote serivce supports ghostnet
		if balanceAndBakerData?.isStakingPossible == true && balanceAndBakerData?.isStaked == true && DependencyManager.shared.currentNetworkType != .testnet {
			loadBakerData { [weak self] result in
				guard let self = self else { return }
				
				switch result {
					case .success(let data):
						self.currentSnapshot.deleteItems([self.stakingRewardLoadingData])
						self.stakingRewardData = data
						self.currentSnapshot.insertItems([data], afterItem: self.sendData)
						
						ds.apply(self.currentSnapshot, animatingDifferences: true)
						
					case .failure(let error):
						self.state = .failure(error, "Unable to get baker data")
				}
			}
		}
	}
	
	
	
	// MARK: - Data
	
	public static func deleteAllCachedData() {
		let _ = DiskService.delete(fileName: TokenDetailsViewModel.bakerRewardsCacheFilename)
	}
	
	func loadTokenData(token: Token) {
		self.token = token
		self.tokenHeaderData.tokenName = token.symbol
		
		let tokenBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.balance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		
		if token.isXTZ() {
			self.tokenHeaderData.tokenImage = UIImage.tezosToken()
			self.tokenHeaderData.tokenName = "XTZ"
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			tokenFiatPrice = DependencyManager.shared.coinGeckoService.format(decimal: fiatPerToken, numberStyle: .currency, maximumFractionDigits: 2)
			self.tokenHeaderData.fiatAmount = tokenFiatPrice
			
			let account = DependencyManager.shared.balanceService.account
			let xtzValue = (token.balance as? XTZAmount ?? .zero()) * fiatPerToken
			let tokenValue = DependencyManager.shared.coinGeckoService.format(decimal: xtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			let bakerString = (account.delegate?.alias ?? account.delegate?.address.truncateTezosAddress() ?? "") + "  "
			
			buttonData = TokenDetailsButtonData(isFavourited: true, canBeUnFavourited: false, isHidden: false, canBeHidden: false, canBePurchased: true, canBeViewedOnline: false, hasMoreButton: false)
			balanceAndBakerData = TokenDetailsBalanceAndBakerData(balance: tokenBalance, value: tokenValue, isStakingPossible: true, isStaked: (account.delegate != nil), bakerName: bakerString)
			
		} else {
			self.tokenHeaderData.tokenURL = token.thumbnailURL
			self.tokenHeaderData.tokenName = token.symbol
			
			let isFav = token.isFavourite
			let isHidden = token.isHidden
			buttonData = TokenDetailsButtonData(isFavourited: isFav, canBeUnFavourited: true, isHidden: isHidden, canBeHidden: true, canBePurchased: false, canBeViewedOnline: true, hasMoreButton: true)
			
			if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
				var tokenPriceString = ""
				let fiatPerToken = tokenValueAndRate.marketRate
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
				
				balanceAndBakerData = TokenDetailsBalanceAndBakerData(balance: tokenBalance, value: tokenBalanceValueString, isStakingPossible: false, isStaked: false, bakerName: "")
				
			} else {
				let dashedString = DependencyManager.shared.coinGeckoService.dashedCurrencyString()
				tokenHeaderData.fiatAmount = dashedString
				balanceAndBakerData = TokenDetailsBalanceAndBakerData(balance: tokenBalance, value: dashedString, isStakingPossible: false, isStaked: false, bakerName: "")
			}
		}
	}
	
	func loadBakerData(completion: @escaping ((Result<AggregateRewardInformation, KukaiError>) -> Void)) {
		let account = DependencyManager.shared.balanceService.account
		guard let delegate = account.delegate else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find baker details")))
			return
		}
		
		if let bakerRewardCache = DiskService.read(type: AggregateRewardInformation.self, fromFileName: TokenDetailsViewModel.bakerRewardsCacheFilename), !bakerRewardCache.isOutOfDate(), !bakerRewardCache.moreThan1CycleBetweenPreiousAndNext() {
			completion(Result.success(bakerRewardCache))
			
		} else {
			DependencyManager.shared.tzktClient.estimateLastAndNextReward(forAddress: account.walletAddress, delegate: delegate) { result in
				if let res = try? result.get() {
					let _ = DiskService.write(encodable: res, toFileName: TokenDetailsViewModel.bakerRewardsCacheFilename)
					completion(Result.success(res))
					
				} else {
					completion(Result.failure(result.getFailure()))
				}
			}
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
