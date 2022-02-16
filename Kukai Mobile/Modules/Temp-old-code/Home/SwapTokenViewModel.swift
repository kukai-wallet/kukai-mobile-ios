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
	
	private var tokens: [DipDupExchangesAndTokens] = []
	
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
			
			/*
			guard let exchange = item as? DipDupExchange else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell", for: indexPath) as? SwapTokenCell
			cell?.dexLabel.text = self?.dexName(dex: exchange.name)
			cell?.priceLabel.text = exchange.midPrice + " XTZ"
			cell?.xtzPoolLabel.text = exchange.xtzPoolAmount().normalisedRepresentation
			cell?.tokenPoolLabel.text = exchange.tokenPoolAmount().normalisedRepresentation
			
			return cell
			*/
			
			return UITableViewCell()
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
		if !state.isLoading() {
			state = .loading
		}
		
		
		DependencyManager.shared.dipDupClient.getAllExchangesAndTokens { [weak self] result in
			guard let tokens = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data. Please check internet connection and try again")
				return
			}
			
			guard let ds = self?.dataSource else {
				self?.state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
				return
			}
			
			self?.tokens = tokens
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			
			snapshot.appendSections(Array(0...tokens.count))
			
			for (index, tokenObj) in tokens.enumerated() {
				snapshot.appendItems(tokenObj.exchanges, toSection: index)
			}
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success(nil)
		}
	}
	
	func exchange(forIndexPath indexPath: IndexPath) -> DipDupExchange {
		return tokens[indexPath.section].exchanges[indexPath.row]
	}
}
