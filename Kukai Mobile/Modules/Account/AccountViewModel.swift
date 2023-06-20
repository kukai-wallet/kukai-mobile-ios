//
//  AccountViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog
import Kingfisher

struct TotalEstiamtedValue: Hashable {
	let tez: XTZAmount
	let value: String
}

class AccountViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var isPresentedForSelectingToken = false
	var isVisible = false
	var tokensToDisplay: [Token] = []
	var balancesMenuVC: MenuViewController? = nil
	var estimatedTotalCellDelegate: EstimatedTotalCellDelegate? = nil
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && self?.isVisible == true && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}
		
		AccountViewModel.setupAccountActivityListener()
	}
	
	deinit {
		accountDataRefreshedCancellable?.cancel()
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
			
			if let obj = item as? MenuViewController, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceHeaderCell", for: indexPath) as? TokenBalanceHeaderCell {
				cell.setup(menuVC: obj)
				return cell
				
			} else if let amount = item as? XTZAmount, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				cell.iconView.image = UIImage.tezosToken().resizedImage(size: CGSize(width: 50, height: 50))
				cell.symbolLabel.text = "Tez"
				cell.balanceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(amount.toNormalisedDecimal() ?? 0, decimalPlaces: amount.decimalPlaces)
				cell.setPriceChange(value: 100)
				
				let totalXtzValue = amount * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
				cell.valuelabel.text = DependencyManager.shared.coinGeckoService.format(decimal: totalXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
				
				return cell
				
			} else if let token = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				var symbol = token.symbol
				if symbol == "" {
					symbol = " "
				}
				
				cell.iconView.backgroundColor = .colorNamed("BG4")
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, withCacheType: .permanent, fallback: UIImage.unknownToken()) { res in
					cell.iconView.backgroundColor = .white
				}
				
				cell.symbolLabel.text = symbol
				cell.balanceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(token.balance.toNormalisedDecimal() ?? 0, decimalPlaces: token.decimalPlaces)
				cell.setPriceChange(value: Decimal(Int.random(in: -100..<100)))
				
				if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
					let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
					let currencyString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
					cell.valuelabel.text = currencyString
					
				} else {
					cell.valuelabel.text = DependencyManager.shared.coinGeckoService.placeholderCurrencyString()
				}
				
				return cell
				
			} else if let total = item as? TotalEstiamtedValue, let cell = tableView.dequeueReusableCell(withIdentifier: "EstimatedTotalCell", for: indexPath) as? EstimatedTotalCell {
				
				if total.tez.normalisedRepresentation == "-1" {
					cell.balanceLabel.text = "--- tez"
					cell.balanceLabel.textColor = .colorNamed("Txt14")
					cell.valueLabel.text = ""
					cell.delegate = self?.estimatedTotalCellDelegate
					return cell
					
				} else {
					cell.balanceLabel.text = DependencyManager.shared.coinGeckoService.format(decimal: total.tez.toNormalisedDecimal() ?? 0, numberStyle: .decimal) + " tez"
					cell.balanceLabel.textColor = .colorNamed("Txt2")
					cell.valueLabel.text = total.value
					cell.delegate = self?.estimatedTotalCellDelegate
					return cell
				}
				
			} else if let _ = item as? LoadingContainerCellObject, let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingContainerCell", for: indexPath) as? LoadingContainerCell {
				cell.setup()
				return cell
				
			} else {
				return tableView.dequeueReusableCell(withIdentifier: "GhostnetWarningCell", for: indexPath)
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		let isTestnet = DependencyManager.shared.currentNetworkType == .testnet
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		var data: [AnyHashable] = []
		
		if isTestnet {
			data.append(GhostnetWarningCellObj())
		}
		
		// If initial load, display shimmer views
		let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		if DependencyManager.shared.balanceService.hasNotBeenFetched(forAddress: selectedAddress) {
			
			let hashableData: [AnyHashable] = [
				balancesMenuVC,
				TotalEstiamtedValue(tez: XTZAmount(fromNormalisedAmount: -1), value: ""),
				LoadingContainerCellObject(),
				LoadingContainerCellObject(),
				LoadingContainerCellObject()
			]
			
			data.append(contentsOf: hashableData)
			
			snapshot.appendSections([0])
			snapshot.appendItems(data, toSection: 0)
			
		} else {
			
			// Else build arrays of acutal data
			let totalXTZ = DependencyManager.shared.balanceService.estimatedTotalXtz(forAddress: selectedAddress)
			let totalCurrency = totalXTZ * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
			let totalCurrencyString = DependencyManager.shared.coinGeckoService.format(decimal: totalCurrency, numberStyle: .currency, maximumFractionDigits: 2)
			
			data.append(DependencyManager.shared.balanceService.account.xtzBalance)
			
			
			// Group and srot favourites (and remove hidden)
			tokensToDisplay = []
			var nonFavourites: [Token] = []
			
			for token in DependencyManager.shared.balanceService.account.tokens {
				guard !token.isHidden else {
					continue
				}
				
				if token.isFavourite {
					tokensToDisplay.append(token)
				} else {
					nonFavourites.append(token)
				}
			}
			
			tokensToDisplay = tokensToDisplay.sorted(by: { ($0.favouriteSortIndex ?? tokensToDisplay.count) < ($1.favouriteSortIndex ?? tokensToDisplay.count) })
			tokensToDisplay.append(contentsOf: nonFavourites)
			
			data.append(contentsOf: tokensToDisplay)
			
			
			// Build snapshot
			if isPresentedForSelectingToken {
				snapshot.appendSections([0])
				snapshot.appendItems(data, toSection: 0)
				
			} else {
				if tokensToDisplay.count > 0 {
					data.insert(TotalEstiamtedValue(tez: totalXTZ, value: totalCurrencyString), at: isTestnet ? 1 : 0)
				}
				
				data.insert(balancesMenuVC, at: isTestnet ? 1 : 0)
				
				snapshot.appendSections([0])
				snapshot.appendItems(data, toSection: 0)
			}
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func pullToRefresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWalletAddress else {
			state = .failure(.unknown(), "Unable to locate current wallet")
			return
		}
		
		DependencyManager.shared.balanceService.fetch(records: [BalanceService.FetchRequestRecord(address: address, type: .refreshEverything)])
	}
	
	func token(atIndexPath: IndexPath) -> Token? {
		let obj = dataSource?.itemIdentifier(for: atIndexPath)
		
		if obj is XTZAmount {
			return Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
			
		} else if obj is Token {
			return obj as? Token
			
		} else {
			return nil
		}
	}
	
	static func setupAccountActivityListener() {
		let allWallets = DependencyManager.shared.walletList.addresses()
		if DependencyManager.shared.tzktClient.isListening {
			DependencyManager.shared.tzktClient.changeAddressToListenForChanges(addresses: allWallets)
			
		} else {
			DependencyManager.shared.tzktClient.listenForAccountChanges(addresses: allWallets)
		}
	}
}
