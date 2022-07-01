//
//  LiquidityDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2021.
//

import Foundation
import KukaiCoreSwift

class LiquidityDetailsViewModel: ViewModel {
	
	var token: String = ""
	var amount: String = ""
	var xtzReturned: String = ""
	var tokenReturned: String = ""
	var pendingRewardsSupported = false
	var pendingRewardsAmount: XTZAmount = XTZAmount.zero()
	var pendingRewardsDisplay: String {
		get {
			return pendingRewardsAmount.normalisedRepresentation + " XTZ"
		}
	}
	
	private var calculation: DexRemoveCalculationResult? = nil
	
	/*
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let selectedPosition = TransactionService.shared.removeLiquidityData.position, let address = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(KukaiError.unknown(), "Can't find selected data")
			return
		}
		
		self.token = selectedPosition.exchange.token.symbol
		self.amount = selectedPosition.tokenAmount().normalisedRepresentation
		
		self.pendingRewardsSupported = (selectedPosition.exchange.name == .quipuswap)
		
		
		DAppHelperService.Quipuswap.getPendingRewards(fromExchange: selectedPosition.exchange.address, forAddress: address, tzKTClient: DependencyManager.shared.tzktClient) { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Couldn't get rewards info")
				return
			}
			
			self?.pendingRewardsAmount = res
			
			self?.state = .success(nil)
		}
	}
	
	func checkPrice(forEnteredLiquidity: String) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let selectedPosition = TransactionService.shared.removeLiquidityData.position, let liquidity = TokenAmount(fromNormalisedAmount: forEnteredLiquidity, decimalPlaces: selectedPosition.exchange.liquidityTokenDecimalPlaces()) else {
			state = .failure(KukaiError.unknown(), "Can't find selected data")
			return
		}
		
		
		let totalLiquidity = selectedPosition.exchange.totalLiquidity()
		let xtzPool = selectedPosition.exchange.xtzPoolAmount()
		let tokenPool = selectedPosition.exchange.tokenPoolAmount()
		let dex = selectedPosition.exchange.name
		
		if let calc = DexCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: liquidity, totalLiquidity: totalLiquidity, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5, dex: dex) {
			calculation = calc
		}
		
		self.xtzReturned = calculation?.expectedXTZ.normalisedRepresentation ?? ""
		self.tokenReturned = calculation?.expectedToken.normalisedRepresentation ?? ""
		
		self.state = .success(nil)
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
	
	func removeLiquidity() {
		state = .loading
		
		guard let wallet = DependencyManager.shared.selectedWallet else {
			state = .failure(KukaiError.unknown(), "Can't find wallet")
			return
		}
		
		guard let selectedPosition = TransactionService.shared.removeLiquidityData.position, let calc = calculation else {
			state = .failure(KukaiError.unknown(), "Can't find selected data, or price hasn't been checked")
			return
		}
		
		let operations = OperationFactory.removeLiquidity(withDex: selectedPosition.exchange.name,
														  minXTZ: calc.minimumXTZ,
														  minToken: calc.minimumToken,
														  liquidityToBurn: selectedPosition.tokenAmount(),
														  dexContract: selectedPosition.exchange.address,
														  wallet: wallet,
														  timeout: 60 * 5)
		
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
		}
	}
	
	func withdrawRewards() {
		state = .loading
		
		guard let wallet = DependencyManager.shared.selectedWallet else {
			state = .failure(KukaiError.unknown(), "Can't find wallet")
			return
		}
		
		guard let selectedPosition = TransactionService.shared.removeLiquidityData.position else {
			state = .failure(KukaiError.unknown(), "Can't find selected data")
			return
		}
		
		let operations = OperationFactory.withdrawRewards(withDex: selectedPosition.exchange.name, dexContract: selectedPosition.exchange.address, wallet: wallet)
		
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
		}
	}
	*/
}
