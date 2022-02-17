//
//  CurrencyViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/02/2022.
//

import Foundation

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct CurrencyObj: Hashable {
	let code: String
	let name: String
}

class CurrencyViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private let coinGeckoService = DependencyManager.shared.coinGeckoService
	private let popularKeys = ["usd", "eur", "gbp", "jpy", "rub", "inr", "btc", "eth"]
	private var popularCells: [CurrencyObj] = []
	private var otherCells: [CurrencyObj] = []
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			if let currency = item as? CurrencyObj, let cell = tableView.dequeueReusableCell(withIdentifier: "TitleSubtitleCell", for: indexPath) as? TitleSubtitleCell {
				cell.titleLabel.text = currency.code
				cell.subTitleLabel.text = currency.name
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let rates = self.coinGeckoService.exchangeRates?.rates, let ds = dataSource else {
			self.state = .failure(ErrorResponse.unknownError(), "Unable to find currency")
			return
		}
		
		for key in popularKeys {
			if let obj = rates[key] {
				popularCells.append(CurrencyObj(code: key.uppercased(), name: obj.name))
			}
		}
		
		for key in rates.keys.sorted(by: <) where !popularKeys.contains(key) {
			otherCells.append(CurrencyObj(code: key.uppercased(), name: rates[key]?.name ?? ""))
		}
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0, 1])
		
		snapshot.appendItems(popularCells, toSection: 0)
		snapshot.appendItems(otherCells, toSection: 1)
		
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
}