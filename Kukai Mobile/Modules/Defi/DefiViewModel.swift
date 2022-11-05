//
//  DefiViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//

import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class DefiViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	private var positions: [DipDupPositionData] = []
	private var calculations: [DexRemoveCalculationResult] = []
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var isVisible = false
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil && self?.isVisible == true {
					self?.refresh(animate: true)
				}
			}
	}
	
	deinit {
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			// Display "no liquidity tokens" cell if we have no data stored
			if self?.positions.count == 0 {
				return tableView.dequeueReusableCell(withIdentifier: "NoTokensCell", for: indexPath)
			}
			
			// Otherwise, calculate current value and display
			guard let self = self, let position = item as? DipDupPositionData, let cell = tableView.dequeueReusableCell(withIdentifier: "LiquidityTokenCell", for: indexPath) as? LiquidityTokenCell else {
				os_log("Invalid Hashable or cell: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
			
			let calc = self.calculations[indexPath.row]
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: position.exchange.token.address)
			
			cell.tokenIconLeft.image = UIImage(named: "tezos-logo")
			MediaProxyService.load(url: tokenIconURL, to: cell.tokenIconRight, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconRight.frame.size)
			
			cell.pairLabel.text = "tez/\(position.exchange.token.symbol)"
			cell.sourceLabel.text = position.exchange.name == .lb ? "Sirius Dex" : "Quipuswap"
			
			cell.amountLabel.text = position.tokenAmount().normalisedRepresentation
			cell.value1Label.text = "\(calc.expectedXTZ.normalisedRepresentation) tez"
			cell.value2Label.text = "\(calc.expectedToken.normalisedRepresentation) \(position.exchange.token.symbol)"
			
			return cell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = self.dataSource else {
			self.state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		self.positions = DependencyManager.shared.balanceService.account.liquidityTokens
		
		for position in self.positions {
			let liquidity = position.tokenAmount()
			let totalLiquidity = position.exchange.totalLiquidity()
			let xtzPool = position.exchange.xtzPoolAmount()
			let tokenPool = position.exchange.tokenPoolAmount()
			let dex = position.exchange.name
			
			var calculation = DexRemoveCalculationResult(expectedXTZ: XTZAmount.zero(), minimumXTZ: XTZAmount.zero(), expectedToken: TokenAmount.zero(), minimumToken: TokenAmount.zero(), exchangeRate: 0)
			if let calc = DexCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: liquidity, totalLiquidity: totalLiquidity, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.005, dex: dex) {
				calculation = calc
			}
			
			self.calculations.append(calculation)
		}
		
		if self.positions.count == 0 {
			snapshot.appendItems(["No tokens"], toSection: 0)
			
		} else {
			snapshot.appendItems(self.positions, toSection: 0)
		}
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(successMessage)
	}
	
	func position(forIndexPath indexPath: IndexPath) -> DipDupPositionData {
		return self.positions[indexPath.row]
	}
}
