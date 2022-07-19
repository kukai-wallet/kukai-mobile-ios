//
//  SwapTokenViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/11/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class SwapTokenViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	override init() {
		super.init()
	}
	
	deinit {
	}
	
	private class DiffableTableViewWithSectionHeaders: UITableViewDiffableDataSource<Int, AnyHashable> {
		override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
			guard let exchange = self.itemIdentifier(for: IndexPath(item: 0, section: section)) as? DipDupExchange else {
				return ""
			}
			
			return exchange.token.symbol
		}
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = DiffableTableViewWithSectionHeaders(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			guard let exchange = item as? DipDupExchange else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "SwapTokenCell", for: indexPath) as? SwapTokenCell
			cell?.dexLabel.text = self.dexName(dex: exchange.name)
			cell?.priceLabel.text = exchange.midPrice + " XTZ"
			cell?.xtzPoolLabel.text = exchange.xtzPoolAmount().normalisedRepresentation
			cell?.tokenPoolLabel.text = exchange.tokenPoolAmount().normalisedRepresentation
			
			return cell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func dexName(dex: DipDupExchangeName) -> String {
		switch dex {
			case .quipuswap:
				return "Quipuswap"
				
			case .lb:
				return "Liquidity Baking"
				
			case .unknown:
				return "Unknown"
		}
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let address = DependencyManager.shared.selectedWallet?.address else {
			self.state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		if DependencyManager.shared.balanceService.exchangeData.count == 0 {
			DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address, refreshType: .useCache) { [weak self] error in
				if let err = error {
					self?.state = .failure(KukaiError.internalApplicationError(error: err), "Unable to process data at this time 2")
				}
				
				self?.processTokens(animate: animate, successMessage: successMessage)
			}
			
		} else {
			processTokens(animate: animate, successMessage: successMessage)
		}
	}
	
	private func processTokens(animate: Bool, successMessage: String? = nil) {
		guard let ds = self.dataSource else {
			self.state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		let tokens = DependencyManager.shared.balanceService.exchangeData
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		snapshot.appendSections(Array(0...tokens.count))
		
		for (index, tokenObj) in tokens.enumerated() {
			snapshot.appendItems(tokenObj.exchanges, toSection: index)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(nil)
	}
	
	func exchange(forIndexPath indexPath: IndexPath) -> DipDupExchange {
		return DependencyManager.shared.balanceService.exchangeData[indexPath.section].exchanges[indexPath.row]
	}
}
