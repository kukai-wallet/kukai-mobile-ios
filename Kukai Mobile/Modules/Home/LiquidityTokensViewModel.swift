//
//  LiquidityTokensViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/11/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class LiquidityTokensViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var positions: [DipDupPositionData] = []
	private var calculations: [DexRemoveCalculationResult] = []
	
	override init() {
		super.init()
	}
	
	deinit {
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			guard let position = item as? DipDupPositionData else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
			
			let calc = self?.calculations[indexPath.row]
			let dex = self?.dipdupExchangeToTezTool(exchange: position.exchange.name)
			let cell = tableView.dequeueReusableCell(withIdentifier: "liquidityTokenCell", for: indexPath) as? LiquidityTokenCell
			
			cell?.setup(tokenSymbol: position.token.symbol,
						liquidityAmount: position.tokenAmount().normalisedRepresentation,
						dex: dex?.rawValue ?? "",
						xtzValue: calc?.expectedXTZ.normalisedRepresentation ?? "0",
						tokenValue: calc?.expectedToken.normalisedRepresentation ?? "0")
			return cell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func dipdupExchangeToTezTool(exchange: DipDupExchangeName) -> TezToolDex {
		switch exchange {
			case .quipuswap:
				return .quipuswap
				
			case .lb:
				return .liquidityBaking
				
			case .unknown:
				return .unknown
		}
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(ErrorResponse.unknownError(), "Can't find wallet")
			return
		}
		
		DependencyManager.shared.dipDupClient.getLiquidityFor(address: address) { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(result.getFailure(), "DipDup query return failure")
				return
			}
			
			guard let ds = self?.dataSource else {
				self?.state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
				return
			}
			
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections([0])
			
			self?.positions = res.data?.position ?? []
			
			for position in self?.positions ?? [] {
				let liquidity = position.tokenAmount()
				let totalLiquidity = position.exchange.totalLiquidity()
				let xtzPool = position.exchange.xtzPool()
				let tokenPool = position.exchange.tokenPool(decimals: position.token.decimals)
				let dex = self?.dipdupExchangeToTezTool(exchange: position.exchange.name)
				
				var calculation = DexRemoveCalculationResult(expectedXTZ: XTZAmount.zero(), minimumXTZ: XTZAmount.zero(), expectedToken: TokenAmount.zero(), minimumToken: TokenAmount.zero(), exchangeRate: 0)
				if let calc = DexCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: liquidity, totalLiquidity: totalLiquidity, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5, dex: dex ?? .unknown) {
					calculation = calc
				}
				
				self?.calculations.append(calculation)
			}
			
			
			snapshot.appendItems(self?.positions ?? [], toSection: 0)
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success(successMessage)
		}
	}
	
	func position(forIndexPath indexPath: IndexPath) -> DipDupPositionData {
		return self.positions[indexPath.row]
	}
}
