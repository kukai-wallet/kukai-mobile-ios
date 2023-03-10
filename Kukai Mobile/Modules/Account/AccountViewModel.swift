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
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil && self?.isVisible == true {
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
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
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
				if cell.iconView.image == nil {
					cell.iconView.image = UIImage.unknownToken()
				}
				
				let imageSize = CGSize(width: cell.iconView.frame.width+2, height: cell.iconView.frame.height+2)
				var symbol = token.symbol
				if symbol == "" {
					symbol = " "
				}
				
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: imageSize)
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
				cell.balanceLabel.text = DependencyManager.shared.coinGeckoService.format(decimal: total.tez.toNormalisedDecimal() ?? 0, numberStyle: .decimal) + " tez"
				cell.valueLabel.text = total.value
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		// Build arrays of data
		let totalXTZ = DependencyManager.shared.balanceService.estimatedTotalXtz
		let totalCurrency = totalXTZ * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
		let totalCurrencyString = DependencyManager.shared.coinGeckoService.format(decimal: totalCurrency, numberStyle: .currency, maximumFractionDigits: 2)
		
		var section1Data: [AnyHashable] = [DependencyManager.shared.balanceService.account.xtzBalance]
		
		
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
		
		tokensToDisplay = tokensToDisplay.sorted(by: { $0.favouriteSortIndex < $1.favouriteSortIndex})
		tokensToDisplay.append(contentsOf: nonFavourites)
		
		section1Data.append(contentsOf: tokensToDisplay)
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		if isPresentedForSelectingToken {
			snapshot.appendSections([0])
			snapshot.appendItems(section1Data, toSection: 0)
			
		} else {
			var data: [AnyHashable] = [balancesMenuVC]
			if section1Data.count > 1 {
				data.append(TotalEstiamtedValue(tez: totalXTZ, value: totalCurrencyString))
			}
			
			data.append(contentsOf: section1Data)
			
			snapshot.appendSections([0])
			snapshot.appendItems(data, toSection: 0)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func pullToRefresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		let address = DependencyManager.shared.selectedWalletAddress
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address, refreshType: .refreshEverything) { [weak self] error in
			guard let self = self else { return }
			
			if let e = error {
				self.state = .failure(e, "Unable to fetch data")
			}
			
			self.refresh(animate: animate)
			
			// Return success
			self.state = .success(nil)
		}
	}
	
	func token(atIndexPath: IndexPath) -> Token? {
		if atIndexPath.row == 0 || atIndexPath.row == 1 {
			return nil
		}
		
		if atIndexPath.row == 2 {
			return Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
		} else {
			return tokensToDisplay[atIndexPath.row - 3]
		}
	}
	
	static func setupAccountActivityListener() {
	#if DEBUG
		// Avoid excessive loading / spinning while running on simulator. Using Cache and manual pull to refresh is nearly always sufficient and quicker. Can be commented out if need to test
		return
	#else
		let wallet = DependencyManager.shared.selectedWalletAddress
		if DependencyManager.shared.tzktClient.isListening {
			DependencyManager.shared.tzktClient.changeAddressToListenForChanges(address: wallet)
			
		} else {
			DependencyManager.shared.tzktClient.listenForAccountChanges(address: wallet)
		}
	#endif
	}
}
