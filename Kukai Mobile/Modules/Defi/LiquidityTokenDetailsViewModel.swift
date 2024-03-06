//
//  LiquidityTokenDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2022.
//

/*
import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class LiquidityTokenDetailsViewModel: ViewModel {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	public var amount: String = "0"
	public var withdrawEnabled: Bool = false
	
	override init() {
		super.init()
	}
	
	deinit {
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		/*let address = DependencyManager.shared.selectedWalletAddress
		guard let selectedPosition = TransactionService.shared.liquidityDetails.selectedPosition else {
			self.state = .failure(KukaiError.unknown(withString: "Can't find wallet"), "Can't find wallet")
			return
		}*/
		
		
		if !state.isLoading() {
			state = .loading
		}
		
		/*
		DAppHelperService.Quipuswap.getPendingRewards(fromExchange: selectedPosition.exchange.address, forAddress: address, tzKTClient: DependencyManager.shared.tzktClient) { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Couldn't get rewards info")
				return
			}
			
			self?.amount = res.normalisedRepresentation + " XTZ"
			self?.withdrawEnabled = res > XTZAmount.zero()
			self?.state = .success(successMessage)
		}
		*/
	}
	
	func withdrawRewards() {
		/*state = .loading
		
		guard let wallet = DependencyManager.shared.selectedWallet else {
			state = .failure(KukaiError.unknown(), "Can't find wallet")
			return
		}
		
		guard let selectedPosition = TransactionService.shared.liquidityDetails.selectedPosition else {
			state = .failure(KukaiError.unknown(), "Can't find selected data")
			return
		}
		
		let operations = OperationFactory.withdrawRewards(withDex: selectedPosition.exchange, wallet: wallet)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			switch result {
				case .success(let ops):
					DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { [weak self] innerResult in
						switch innerResult {
							case .success(let opHash):
								self?.state = .success("Success: \(opHash)")
								
							case .failure(let error):
								self?.state = .failure(error, error.description)
						}
					}
					
				case .failure(let error):
					self?.state = .failure(error, error.description)
			}
		}*/
	}
}
*/
