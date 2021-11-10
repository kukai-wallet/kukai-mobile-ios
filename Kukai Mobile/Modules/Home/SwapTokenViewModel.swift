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
	
	private var filteredPairs: [TezToolPair] = []
	
	override init() {
		super.init()
	}
	
	deinit {
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			guard let pair = item as? TezToolPair, let side = pair.nonBaseTokenSide() else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "tokenCell", for: indexPath) as? SwapTokenCell
			cell?.tokenLabel.text = side.symbol
			cell?.buyPriceLabel.text = side.price.rounded(scale: 6, roundingMode: .bankers).description
			cell?.dexLabel.text = pair.dex.rawValue
			return cell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		
		DependencyManager.shared.tezToolsClient.fetchTokens { [weak self] result in
			guard let tokens = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data. Please check internet connection and try again")
				return
			}
			
			guard let ds = self?.dataSource else {
				self?.state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
				return
			}
			
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections([0])
			
			self?.filteredPairs = []
			for token in tokens {
				for pair in token.price.pairs {
					if pair.dex == .liquidityBaking || pair.dex == .quipuswap {
						self?.filteredPairs.append(pair)
					}
				}
			}
			
			snapshot.appendItems(self?.filteredPairs ?? [], toSection: 0)
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success
		}
	}
	
	func pairFor(indexPath: IndexPath) -> TezToolPair {
		return self.filteredPairs[indexPath.row]
	}
}
