//
//  TokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
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
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
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
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct TokenDetailsBalanceData: Hashable, Identifiable {
	let id = UUID()
	let balance: String
	let value: String
	let availableBalance: String
	let availableValue: String
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct TokenDetailsSendData: Hashable {
	var isBuyTez: Bool
	var isDisabled: Bool
}

struct TokenDetailsBakerData: Hashable {
	let bakerIcon: URL?
	let bakerName: String?
	let bakerApy: Decimal
	let votingParticipation: [Bool]
	let freeSpace: Decimal
	let enoughSpaceForBalance: Bool
	let bakerChangeDisabled: Bool
}

struct TokenDetailsStakeData: Hashable {
	let stakedBalance: String
	let stakedValue: String
	let finalizeBalance: String
	let finalizeValue: String
	let canStake: Bool
	let canUnstake: Bool
	let canFinalize: Bool
	let buttonsDisabled: Bool
}

struct TokenDetailsActivityHeader: Hashable, Identifiable {
	let id = UUID()
	let header: Bool
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct TokenDetailsMessageData: Hashable {
	let message: String
}

struct TokenDetailsSmallSectionHeader: Hashable {
	let message: String
}

struct PendingUnstakeData: Hashable {
	let id = UUID()
	let amount: XTZAmount
	let fiat: String
	let timeRemaining: String
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}



@objc protocol TokenDetailsViewModelDelegate: AnyObject {
	func sendTapped()
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
	private var bag = [AnyCancellable]()
	
	// Set by VC
	weak var delegate: (TokenDetailsViewModelDelegate & TokenDetailsBakerDelegate & TokenDetailsStakeBalanceDelegate)? = nil
	
	var token: Token? = nil
	var baker: TzKTBaker? = nil
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
	var pendingUnstakes: [PendingUnstakeData] = []
	var onlineDataLoading = LoadingData()
	var rewardData: AggregateRewardInformation? = nil
	var activityHeaderData = TokenDetailsActivityHeader(header: true)
	var activityFooterData = TokenDetailsActivityHeader(header: false)
	var activityItems: [TzKTTransactionGroup] = []
	var noItemsData = TokenDetailsMessageData(message: "No items avaialble at this time, check again later")
	var finaliseableAmount: TokenAmount = .zero()
	
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}.store(in: &bag)
	}
	
	// deinit doesn't reliably call, even when the parent VC does call deinit.
	// add backup for now until more testing can be done
	deinit {
		cleanup()
	}
	
	func cleanup() {
		bag.forEach({ $0.cancel() })
	}
	
	
	
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
		tableView.register(UINib(nibName: "TokenDetailsPendingUnstakeCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsPendingUnstakeCell")
		tableView.register(UINib(nibName: "TokenDetailsSmallHeadingCell", bundle: nil), forCellReuseIdentifier: "TokenDetailsSmallHeadingCell")
		
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
				cell.delegate = self.delegate
				return cell
				
			} else if let obj = item.base as? TokenDetailsStakeData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakeBalanceCell", for: indexPath) as? TokenDetailsStakeBalanceCell {
				cell.setup(data: obj)
				cell.delegate = self.delegate
				return cell
				
			} else if let obj = item.base as? TokenDetailsSmallSectionHeader, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsSmallHeadingCell", for: indexPath) as? TokenDetailsSmallHeadingCell {
				cell.headingLabel.text = obj.message
				return cell
				
			} else if let obj = item.base as? PendingUnstakeData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsPendingUnstakeCell", for: indexPath) as? TokenDetailsPendingUnstakeCell {
				cell.setup(data: obj)
				return cell
				
			} else if let _ = item.base as? LoadingData, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsLoadingCell", for: indexPath) as? TokenDetailsLoadingCell {
				cell.setup()
				return cell
				
			} else if let obj = item.base as? AggregateRewardInformation, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenDetailsStakingRewardsCell", for: indexPath) as? TokenDetailsStakingRewardsCell {
				//cell.infoButton.addTarget(self.delegate, action: #selector(TokenDetailsViewModelDelegate.stakingRewardsInfoTapped), for: .touchUpInside)
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
		
		let isWatchWallet = DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false
		
		// Immediately load balance, logo, buttons and placeholder chart
		loadOfflineData(token: token)
		sendData.isBuyTez = (token.isXTZ() && token.balance == .zero())
		sendData.isDisabled = isWatchWallet
		
		var data: [AnyHashableSendable] = [
			.init(tokenHeaderData),
			.init(chartData),
			.init(balanceData),
			.init(sendData)
		]
		
		if token.isXTZ() {
			
			// If XTZ, user has a blance, and we have a delegate set, then we need to fetch more data before displaying anything else
			// Otherwise load the baker onboarding flow, if user has a balance
			if DependencyManager.shared.balanceService.account.delegate != nil {
				self.needsToLoadOnlineXTZData = !sendData.isBuyTez
				data.append(.init(onlineDataLoading))
				
			} else if !sendData.isBuyTez {
				data.append(.init(TokenDetailsBakerData(bakerIcon: nil, bakerName: nil, bakerApy: 0, votingParticipation: [], freeSpace: 0, enoughSpaceForBalance: false, bakerChangeDisabled: isWatchWallet) ))
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
		
		
		// Strange crash reports indicate this may be running too fast for iOS to keep up, in instances where the pricing call fails quickly
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			// After UI is updated, fetch the data for chart and reload that 1 cell
			self?.loadChartData(token: token) { [weak self] result in
				guard let self = self/*, let _ = self.currentSnapshot.itemIdentifiers.firstIndex(of: .init(self.tokenHeaderData))*/ else { return }
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
			
			
			// At the same time, if we should, load all the other XTZ related content, like baker, staking view, delegation/staking rewards, etc
			if self?.needsToLoadOnlineXTZData == true {
				
				// Need to grab the XTZ token again, as these details might change during background refreshes
				let account = DependencyManager.shared.balanceService.account
				let token = Token.xtz(withAmount: account.xtzBalance, stakedAmount: account.xtzStakedBalance, unstakedAmount: account.xtzUnstakedBalance)
				
				self?.loadOnlineXTZData(token: token) { [weak self] error in
					if let err = error {
						self?.state = .failure(err, err.rpcErrorString ?? err.description)
					}
					
					guard let self = self, let _ = self.currentSnapshot.itemIdentifiers.firstIndex(of: .init(self.sendData)) else { return }
					
					self.currentSnapshot.deleteItems([.init(self.onlineDataLoading)])
					
					var newData: [AnyHashableSendable] = [.init(self.bakerData), .init(self.stakeData)]
					
					if pendingUnstakes.count > 0 {
						newData.append(.init(TokenDetailsSmallSectionHeader(message: "Pending Unstake Requests")))
						newData.append(contentsOf: pendingUnstakes.map({ .init($0) }))
					}
					
					if let rewardData = rewardData {
						newData.append(.init(TokenDetailsSmallSectionHeader(message: "Delegation & Staking Rewards")))
						newData.append(.init(rewardData))
					}
					
					newData.append(contentsOf: loadActivitySection(token: token))
					self.currentSnapshot.insertItems(newData, afterItem: .init(self.sendData))
					
					ds.apply(self.currentSnapshot, animatingDifferences: true)
					self.state = .success(nil)
				}
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
	
	func loadOnlineXTZData(token: Token, completion: @escaping ((KukaiError?) -> Void)) {
		guard let delegate = DependencyManager.shared.balanceService.account.delegate else {
			completion(nil)
			return
		}
		
		let isWatchWallet = DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false
		let isExperimental = (DependencyManager.shared.currentNetworkType == .experimental && DependencyManager.shared.currentTzktURL == nil)
		let account = DependencyManager.shared.balanceService.account
		var votingParticipation: [Bool] = []
		
		
		if isExperimental {
			// If we are running on experimental, we have no way of finding much of this data. However, this blocks access to UI elements
			// Experimental users should be advanced enough to understand how to verify these things themseleves, so we create some fake inputs that will pass the later logic checks
			let account = DependencyManager.shared.balanceService.account
			let doubleBalance = (account.xtzBalance * 2).toNormalisedDecimal() ?? 0
			let bakerAddress = account.delegate?.address ?? ""
			let settings = TzKTBakerSettings(enabled: true, minBalance: 0, fee: 0.05, capacity: doubleBalance, freeSpace: doubleBalance, estimatedApy: 5)
			
			self.baker = TzKTBaker(address: bakerAddress, name: nil, status: .active, balance: doubleBalance, delegation: settings, staking: settings)
			
		} else {
			// Get fresh baker data, as rewards are cached for an entire cycle and free space could change very regularly
			onlineXTZFetchGroup.enter()
			DependencyManager.shared.tzktClient.bakerConfig(forAddress: delegate.address) { [weak self] result in
				guard let res = try? result.get() else {
					self?.onlineXTZFetchGroup.leave()
					return
				}
				
				self?.baker = res
				self?.onlineXTZFetchGroup.leave()
			}
		}
		
		
		// Fetch all the pending unstake items
		onlineXTZFetchGroup.enter()
		DependencyManager.shared.tzktClient.pendingStakingUpdates(forAddress: account.walletAddress, ofType: "unstake") { [weak self] result in
			guard let res = try? result.get() else {
				self?.onlineXTZFetchGroup.leave()
				return
			}
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			self?.pendingUnstakes = res.map { item in
				let xtzAmount = item.xtzAmount
				let xtzValue = xtzAmount * fiatPerToken
				let xtzValueString = DependencyManager.shared.coinGeckoService.format(decimal: xtzValue, numberStyle: .currency, maximumFractionDigits: 2)
				
				return PendingUnstakeData(amount: item.xtzAmount, fiat: xtzValueString, timeRemaining: item.dateTime.timeAgoDisplay())
			}
			
			self?.onlineXTZFetchGroup.leave()
		}
		
		
		// Get rewards data from cache or remote
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
		
		
		// Certain things only work or make sense on mainnet
		if DependencyManager.shared.currentNetworkType != .ghostnet {
			
			// Check voting participation
			onlineXTZFetchGroup.enter()
			DependencyManager.shared.tzktClient.checkBakerVoteParticipation(forAddress: delegate.address) {[weak self] result in
				guard let res = try? result.get() else {
					self?.onlineXTZFetchGroup.leave()
					return
				}
				
				votingParticipation = res
				self?.onlineXTZFetchGroup.leave()
			}
		}
		
		
		// Fire completion when everything is done
		onlineXTZFetchGroup.notify(queue: .global(qos: .background)) { [weak self] in
			guard let baker = self?.baker else {
				DispatchQueue.main.async { completion(KukaiError.unknown(withString: "Unable to fetch information about the current baker. Please try again later")) }
				return
			}
			
			let fiatPerToken = DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			let isStaking = account.xtzStakedBalance > .zero()
			
			let bakerString = delegate.alias ?? delegate.address.truncateTezosAddress()
			let freeSpace = isStaking ? baker.staking.freeSpace : baker.delegation.freeSpace
			let enoughSpace = isStaking ? account.availableBalance < XTZAmount(fromNormalisedAmount: baker.staking.freeSpace) : account.xtzBalance < XTZAmount(fromNormalisedAmount: baker.delegation.freeSpace)
			
			let delegationApy = Decimal(baker.delegation.estimatedApy)
			let stakingApy = Decimal(baker.staking.estimatedApy)
			let percentOfFundsStaked = ((account.xtzStakedBalance.toNormalisedDecimal() ?? 0) / (account.xtzBalance.toNormalisedDecimal() ?? 0))
			let percentOfFundsDelegated = 1 - percentOfFundsStaked
			let estimatedApy = (((delegationApy * percentOfFundsDelegated) + (stakingApy * percentOfFundsStaked)) * 100).rounded(scale: 2, roundingMode: .bankers)
			
			self?.bakerData = TokenDetailsBakerData(bakerIcon: baker.logo, bakerName: bakerString, bakerApy: estimatedApy, votingParticipation: votingParticipation, freeSpace: freeSpace, enoughSpaceForBalance: enoughSpace, bakerChangeDisabled: isWatchWallet)
			
			
			
			let stakeBalance = DependencyManager.shared.coinGeckoService.format(decimal: token.stakedBalance.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
			let stakeXtzValue = (token.stakedBalance as? XTZAmount ?? .zero()) * fiatPerToken
			let stakeValue = DependencyManager.shared.coinGeckoService.format(decimal: stakeXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			let totalAmountOfPendingUnstake = self?.pendingUnstakes.map({ $0.amount }).reduce(.zero(), +)
			var actualFinaliseableAmount = token.unstakedBalance - (totalAmountOfPendingUnstake ?? .zero())
			
			if isExperimental {
				// If we are running on experimental mode without tzkt, finalisable balance comes from somewhere else
				actualFinaliseableAmount = account.xtzFinalisedBalance ?? .zero()
			}
			
			self?.finaliseableAmount = actualFinaliseableAmount
			let finaliseBalance = DependencyManager.shared.coinGeckoService.format(decimal: actualFinaliseableAmount.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
			let finaliseXtzValue = actualFinaliseableAmount * fiatPerToken
			let finaliseValue = DependencyManager.shared.coinGeckoService.format(decimal: finaliseXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
			
			// We need to prevent users from staking their entire balance so that they have enough balance to unstake
			// User can also only stake if the baker has enough free space for them
			let canStake = (account.availableBalance > XTZAmount(fromNormalisedAmount: 1) && enoughSpace)
			let canUnstake = token.stakedBalance > .zero()
			let canFinalize = actualFinaliseableAmount > .zero()
			
			self?.stakeData = TokenDetailsStakeData(stakedBalance: stakeBalance, stakedValue: stakeValue, finalizeBalance: finaliseBalance, finalizeValue: finaliseValue, canStake: canStake, canUnstake: canUnstake, canFinalize: canFinalize, buttonsDisabled: isWatchWallet)
			
			DispatchQueue.main.async { completion(nil) }
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
	
	func isNewBakerFlow() -> Bool {
		return bakerData?.bakerName == nil
	}
	
	func createFinaliseOperations(completion: @escaping ((String?) -> Void)) {
		guard let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else {
			completion("error-no-destination".localized())
			return
		}
		
		TransactionService.shared.currentTransactionType = .finaliseUnstake
		TransactionService.shared.finaliseUnstakeData.chosenAmount = finaliseableAmount
		TransactionService.shared.finaliseUnstakeData.chosenBaker = baker
		TransactionService.shared.finaliseUnstakeData.chosenToken = token
		let operations = OperationFactory.finaliseUnstakeOperation(from: selectedWalletMetadata.address)
		
		// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWalletMetadata.address, base58EncodedPublicKey: selectedWalletMetadata.bas58EncodedPublicKey, isRemote: false) { estimationResult in
			
			switch estimationResult {
				case .success(let estimationResult):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimationResult.operations)
					TransactionService.shared.currentForgedString = estimationResult.forgedString
					completion(nil)
					
				case .failure(let estimationError):
					completion(estimationError.description)
			}
		}
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
