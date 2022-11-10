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
				cell.iconView.image = UIImage(named: "tezos-logo")
				cell.symbolLabel.text = "Tezos"
				cell.balanceLabel.text = amount.normalisedRepresentation
				
				//let singleXTZCurrencyString = DependencyManager.shared.coinGeckoService.format(decimal: DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ, numberStyle: .currency, maximumFractionDigits: 2)
				//cell.rateLabel.text = "1 = \(singleXTZCurrencyString)"
				
				if indexPath.row % 2 == 0 {
					cell.priceChangeIcon.image = UIImage(named: "arrow-up-green")
					cell.priceChangeLabel.text = "\(Int.random(in: 1..<100))%"
					cell.priceChangeLabel.textColor = UIColor.colorNamed("Positive-500")
					
				} else {
					cell.priceChangeIcon.image = UIImage(named: "arrow-down-red")
					cell.priceChangeLabel.text = "\(Int.random(in: 1..<100))%"
					cell.priceChangeLabel.textColor = UIColor.colorNamed("Caution-900")
				}
				
				let totalXtzValue = amount * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
				cell.valuelabel.text = DependencyManager.shared.coinGeckoService.format(decimal: totalXtzValue, numberStyle: .currency, maximumFractionDigits: 2)
				
				return cell
				
			} else if let token = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				if cell.iconView.image == nil {
					cell.iconView.image = UIImage(named: "unknown-token")
				}
				
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(named: "unknown-token") ?? UIImage(), downSampleSize: cell.iconView.frame.size)
				cell.symbolLabel.text = token.symbol
				cell.balanceLabel.text = token.balance.normalisedRepresentation
				
				if indexPath.row % 2 == 0 {
					cell.priceChangeIcon.image = UIImage(named: "arrow-up-green")
					cell.priceChangeLabel.text = "\(Int.random(in: 1..<100))%"
					cell.priceChangeLabel.textColor = UIColor.colorNamed("Positive-500")
					
				} else {
					cell.priceChangeIcon.image = UIImage(named: "arrow-down-red")
					cell.priceChangeLabel.text = "\(Int.random(in: 1..<100))%"
					cell.priceChangeLabel.textColor = UIColor.colorNamed("Caution-900")
				}
				
				if let tokenValueAndRate = DependencyManager.shared.balanceService.tokenValueAndRate[token.id] {
					let xtzPrice = tokenValueAndRate.xtzValue * DependencyManager.shared.coinGeckoService.selectedCurrencyRatePerXTZ
					let currencyString = DependencyManager.shared.coinGeckoService.format(decimal: xtzPrice, numberStyle: .currency, maximumFractionDigits: 2)
					
					//cell.rateLabel.text = "1 == \(tokenValueAndRate.marketRate.rounded(scale: 6, roundingMode: .down)) XTZ"
					cell.valuelabel.text = currencyString
					
				} else {
					//cell.rateLabel.text = ""
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
			var data: [AnyHashable] = [total]
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
	
	func token(atIndexPath: IndexPath) -> Token? {
		if atIndexPath.row == 0 {
			return nil
		}
		
		if atIndexPath.row == 1 {
			return Token.xtz(withAmount: DependencyManager.shared.balanceService.account.xtzBalance)
		} else {
			return DependencyManager.shared.balanceService.account.tokens[atIndexPath.row - 1]
		}
	}
	
	static func setupAccountActivityListener() {
		guard let wallet = DependencyManager.shared.selectedWallet?.address else {
			return
		}
		
		// TODO: revert
		/*
		if DependencyManager.shared.tzktClient.isListening {
			DependencyManager.shared.tzktClient.changeAddressToListenForChanges(address: wallet)
			
		} else {
			DependencyManager.shared.tzktClient.listenForAccountChanges(address: wallet)
		}
		*/
	}
}
