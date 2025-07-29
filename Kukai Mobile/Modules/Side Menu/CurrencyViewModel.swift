//
//  CurrencyViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct CurrencyObj: Hashable {
	let id = UUID()
	let code: String
	let name: String
}

class CurrencyViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	public static let didChangeCurrencyMessage = "changed"
	public var isLoading = false
	public var selectedIndex: IndexPath = IndexPath(row: -1, section: 0)
	
	private let coinGeckoService = DependencyManager.shared.coinGeckoService
	private let popularKeys = ["usd", "eur", "gbp", "jpy", "rub", "inr"]
	private var popularCells: [CurrencyObj] = []
	private var otherCells: [CurrencyObj] = []
	private var cancellable: AnyCancellable? = nil
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			if let currency = item.base as? CurrencyObj, let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyChoiceCell", for: indexPath) as? CurrencyChoiceCell {
				cell.codeLabel.text = currency.code
				cell.nameLabel.text = currency.name
				
				if DependencyManager.shared.coinGeckoService.selectedCurrency == currency.code.lowercased() {
					self?.selectedIndex = indexPath
				}
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let rates = self.coinGeckoService.exchangeRates?.rates, let ds = dataSource else {
			self.state = .failure(KukaiError.unknown(), "Unable to find currency")
			return
		}
		
		let fiatOnly = rates.filter { (key: String, value: CoinGeckoExchangeRate) in
			return value.type == "fiat"
		}
		
		for key in popularKeys {
			if let obj = fiatOnly[key] {
				popularCells.append(CurrencyObj(code: key.uppercased(), name: obj.name))
			}
		}
		
		for key in fiatOnly.keys.sorted(by: <) where !popularKeys.contains(key) {
			otherCells.append(CurrencyObj(code: key.uppercased(), name: fiatOnly[key]?.name ?? ""))
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0, 1])
		
		snapshot.appendItems(popularCells.map({ .init($0) }), toSection: 0)
		snapshot.appendItems(otherCells.map({ .init($0) }), toSection: 1)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	func code(forIndexPath indexPath: IndexPath) -> String {
		if indexPath.section == 0 {
			return popularCells[indexPath.row].code.lowercased()
			
		} else {
			return otherCells[indexPath.row].code.lowercased()
		}
	}
	
	func changeCurrency(toIndexPath indexPath: IndexPath) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let walletAddress = DependencyManager.shared.selectedWalletAddress else {
			state = .failure(.unknown(), "Unable to locate current wallet")
			return
		}
		
		let code = code(forIndexPath: indexPath)
		
		DependencyManager.shared.coinGeckoService.setSelectedCurrency(currency: code) { [weak self] error in
			if let e = error {
				self?.state = .failure(KukaiError.unknown(), "Unable to change currency: \(e)")
				return
			}
			
			self?.cancellable = DependencyManager.shared.$addressRefreshed
				.dropFirst()
				.sink { address in
					if address == walletAddress {
						self?.state = .success(CurrencyViewModel.didChangeCurrencyMessage)
						self?.cancellable = nil
					}
				}
			
			DependencyManager.shared.currencyChanged = true
			DependencyManager.shared.balanceService.fetch(records: [BalanceService.FetchRequestRecord(address: walletAddress, type: .refreshEverything)])
		}
	}
}
