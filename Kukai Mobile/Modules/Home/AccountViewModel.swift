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
			
			if let amount = item as? XTZAmount, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				cell.iconView.image = UIImage(named: "tezos-xtz-logo")
				cell.symbolLabel.text = "Tezos"
				cell.balanceLabel.text = amount.normalisedRepresentation
				
				let singleXTZCurrencyString = DependencyManager.shared.coinGeckoService.format(decimal: DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ, numberStyle: .currency, maximumFractionDigits: 2)
				cell.rateLabel.text = "1 = \(singleXTZCurrencyString)"
				
				let totalXtzValue = amount * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
				cell.valuelabel.text = DependencyManager.shared.coinGeckoService.format(decimal: totalXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
				
				return cell
				
			} else if let token = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				
				cell.symbolLabel.text = token.symbol
				cell.balanceLabel.text = token.balance.normalisedRepresentation
				
				if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
					let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
					let currencyString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
					
					cell.rateLabel.text = "1 == \(tokenValueAndRate.marketRate.rounded(scale: 6, roundingMode: .down)) XTZ"
					cell.valuelabel.text = currencyString
					
				} else {
					cell.rateLabel.text = ""
					cell.valuelabel.text = DependencyManager.shared.coinGeckoService.placeholderCurrencyString()
				}
				
				return cell
				
			} else if let total = item as? TotalEstiamtedValue, let cell = tableView.dequeueReusableCell(withIdentifier: "EstimatedTotalCell", for: indexPath) as? EstimatedTotalCell {
				cell.balanceLabel.text = total.tez.normalisedRepresentation
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
		section1Data.append(contentsOf: DependencyManager.shared.balanceService.account.tokens)
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		if isPresentedForSelectingToken {
			snapshot.appendSections([0])
			snapshot.appendItems(section1Data, toSection: 0)
			
		} else {
			let total = TotalEstiamtedValue(tez: totalXTZ, value: totalCurrencyString)
			section1Data.append(total)
			
			snapshot.appendSections([0])
			snapshot.appendItems(section1Data, toSection: 0)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func pullToRefresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to locate wallet")
			return
		}
		
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
	
	func heightForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> CGFloat {
		let view = viewForHeaderInSection(section, forTableView: tableView)
		view.sizeToFit()
		
		return view.frame.size.height
	}
	
	func viewForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> UIView {
		if isPresentedForSelectingToken {
			return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1)) // If return zero, it defaults to standard transparent headers of size ~20px
		}
		
		if section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "HeadingLargeButtonCell") as? HeadingLargeButtonCell {
			cell.setup(heading: "Balances", buttonTitle: "...")
			return cell.contentView
			
		} else {
			return UIView()
		}
	}
	
	func token(atIndexPath: IndexPath) -> Token {
		if atIndexPath.row == 0 {
			return Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
		} else {
			return DependencyManager.shared.balanceService.account.tokens[atIndexPath.row - 1]
		}
	}
	
	static func setupAccountActivityListener() {
		guard let wallet = DependencyManager.shared.selectedWallet?.address else {
			return
		}
		
		if DependencyManager.shared.tzktClient.isListening {
			DependencyManager.shared.tzktClient.changeAddressToListenForChanges(address: wallet)
			
		} else {
			DependencyManager.shared.tzktClient.listenForAccountChanges(address: wallet)
		}
	}
}
