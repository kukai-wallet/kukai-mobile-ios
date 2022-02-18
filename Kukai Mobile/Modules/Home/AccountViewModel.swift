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

struct DiscoverItem: Hashable {
	let heading: String
	let imageName: String
	let url: String
}

class AccountViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var networkChangeCancellable: AnyCancellable?
	private var walletChangeCancellable: AnyCancellable?
	
	private let balanceService = DependencyManager.shared.balanceService
	private let coinGeckoService = DependencyManager.shared.coinGeckoService
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var discoverItems: [DiscoverItem] = []
	
	
	// MARk: - Init
	
	override init() {
		super.init()
		
		networkChangeCancellable = DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refresh(animate: true)
			}
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refresh(animate: true)
			}
	}
	
	deinit {
		networkChangeCancellable?.cancel()
		walletChangeCancellable?.cancel()
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let amount = item as? XTZAmount, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				cell.iconView.image = UIImage(named: "tezos-xtz-logo")
				cell.symbolLabel.text = "Tezos"
				cell.balanceLabel.text = amount.normalisedRepresentation
				
				let singleXTZCurrencyString = self.coinGeckoService.format(decimal: self.coinGeckoService.selectedCurrencyRatePerXTZ, numberStyle: .currency, maximumFractionDigits: 2)
				cell.rateLabel.text = "1 = \(singleXTZCurrencyString)"
				
				let totalXtzValue = amount * self.coinGeckoService.selectedCurrencyRatePerXTZ
				cell.valuelabel.text = self.coinGeckoService.format(decimal: totalXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
				
				return cell
				
			} else if let token = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				
				cell.symbolLabel.text = token.symbol
				cell.balanceLabel.text = token.balance.normalisedRepresentation
				
				if let tokenValueAndRate = self.balanceService.tokenValueAndRate[token.id] {
					let xtzPrice = tokenValueAndRate.xtzValue * self.coinGeckoService.selectedCurrencyRatePerXTZ
					let currencyString = self.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
					
					cell.rateLabel.text = "1 == \(tokenValueAndRate.marketRate.rounded(scale: 6, roundingMode: .down)) XTZ"
					cell.valuelabel.text = currencyString
					
				} else {
					cell.rateLabel.text = ""
					cell.valuelabel.text = self.coinGeckoService.placeholderCurrencyString()
				}
				
				return cell
				
			} else if let total = item as? TotalEstiamtedValue, let cell = tableView.dequeueReusableCell(withIdentifier: "EstimatedTotalCell", for: indexPath) as? EstimatedTotalCell {
				cell.balanceLabel.text = total.tez.normalisedRepresentation
				cell.valueLabel.text = total.value
				return cell
				
			} else if let discoverItem = item as? DiscoverItem, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as? DiscoverCell {
				cell.headingLabel.text = discoverItem.heading
				cell.iconView.image = UIImage(named: discoverItem.imageName)
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address, let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address) { [weak self] error in
			guard let self = self else { return }
			
			if let e = error {
				self.state = .failure(e, "Unable to fetch data")
			}
			
			self.reloadData(animate: animate, datasource: ds)
			
			// Return success
			self.state = .success(nil)
		}
	}
	
	func reloadData(animate: Bool, datasource: UITableViewDiffableDataSource<Int, AnyHashable>) {
		self.discoverItems = [
			DiscoverItem(heading: "COLLECTIBLES", imageName: "discover-gap", url: "https://www.gap.com/nft/"),
			DiscoverItem(heading: "COLLECTIBLES", imageName: "discover-mooncakes", url: "https://www.mooncakes.fun")
		]
		
		
		// Build arrays of data
		let totalXTZ = self.balanceService.estimatedTotalXtz
		let totalCurrency = totalXTZ * self.coinGeckoService.selectedCurrencyRatePerXTZ
		let totalCurrencyString = self.coinGeckoService.format(decimal: totalCurrency, numberStyle: .currency, maximumFractionDigits: 2)
		
		let total = TotalEstiamtedValue(tez: totalXTZ, value: totalCurrencyString)
		
		var section1Data: [AnyHashable] = [self.balanceService.account.xtzBalance]
		section1Data.append(contentsOf: self.balanceService.account.tokens)
		section1Data.append(total)
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0, 1])
		
		snapshot.appendItems(section1Data, toSection: 0)
		snapshot.appendItems(self.discoverItems, toSection: 1)
		
		datasource.apply(snapshot, animatingDifferences: animate)
		
		self.balanceService.currencyChanged = false
	}
	
	func refreshIfNeeded() {
		if !self.balanceService.hasFetchedInitialData {
			self.refresh(animate: true, successMessage: nil)
			
		} else if self.balanceService.currencyChanged {
			guard let ds = dataSource else {
				state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
				return
			}
			
			self.reloadData(animate: false, datasource: ds)
		}
	}
	
	func heightForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> CGFloat {
		let view = viewForHeaderInSection(section, forTableView: tableView)
		view.sizeToFit()
		
		return view.frame.size.height
	}
	
	func viewForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> UIView {
		
		if section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "HeadingLargeButtonCell") as? HeadingLargeButtonCell {
			cell.setup(heading: "Balances", buttonTitle: "DISCOVER")
			return cell.contentView
			
		} else if section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "HeadingMediumButtonCell") as? HeadingMediumButtonCell {
			cell.setup(heading: "Featured Discoveries", buttonTitle: "ALL")
			return cell.contentView
			
		} else {
			return UIView()
		}
	}
	
	func urlForDiscoverItem(atIndexPath: IndexPath) -> URL? {
		if atIndexPath.section == 1, atIndexPath.row < discoverItems.count  {
			return URL(string: discoverItems[atIndexPath.row].url)
		}
		
		return nil
	}
}
