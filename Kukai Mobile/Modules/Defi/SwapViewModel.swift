//
//  SwapViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/08/2022.
//

import UIKit
import KukaiCoreSwift

class SwapViewModel: ViewModel {
	
	var xtzToToken = true
	var calculationResult: DexSwapCalculationResult? = nil
	var previousExchange: DipDupExchange? = nil
	
	var tokenFromTitle = "XTZ"
	var tokenFromBalanceText = "Balance: 0"
	var tokenFromValidator = TokenAmountValidator(balanceLimit: TokenAmount.zero())
	var tokenFromIconImage: UIImage? = UIImage.tezosToken()
	var tokenFromIconURL: URL? = nil
	var tokenFromTextfieldInput = ""
	
	var tokenToTitle = "..."
	var tokenToBalanceText = "Balance: 0"
	var tokenToIconImage: UIImage? = UIImage()
	var tokenToIconURL: URL? = nil
	var tokenToTextfieldInput = ""
	var exchangeRateText = ""
	
	var isPreviewHidden = true
	
	
	func defaultToFirstAvilableTokenIfNoneSelected() {
		if TransactionService.shared.exchangeData.selectedExchangeAndToken == nil {
			TransactionService.shared.exchangeData.selectedExchangeAndToken = DependencyManager.shared.balanceService.exchangeData[0].exchanges.last
		}
	}
	
	func updateTokenInfo() {
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			return
		}
		
		previousExchange = exchange
		
		let xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
		let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address)
		let tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		if xtzToToken {
			tokenFromTitle = "XTZ"
			tokenFromIconImage = UIImage.tezosToken()
			tokenFromIconURL = nil
			tokenFromBalanceText = "Balance: \(xtzBalance.normalisedRepresentation)"
			tokenFromValidator = TokenAmountValidator(balanceLimit: xtzBalance)
			
			tokenToTitle = exchange.token.symbol
			tokenToIconImage = nil
			tokenToIconURL = tokenIconURL
			tokenToBalanceText = "Balance: \(tokenBalance.normalisedRepresentation)"
			
			let marketRate = DexCalculationService.shared.xtzToTokenMarketRate(xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount())
			exchangeRateText = "1 XTZ = \(marketRate ?? 0) \(exchange.token.symbol)"
			
		} else {
			tokenFromTitle = exchange.token.symbol
			tokenFromIconImage = nil
			tokenFromIconURL = tokenIconURL
			tokenFromBalanceText = "Balance: \(tokenBalance.normalisedRepresentation)"
			tokenFromValidator = TokenAmountValidator(balanceLimit: tokenData?.token.balance ?? TokenAmount.zero(), decimalPlaces: exchange.token.decimals)
			
			tokenToTitle = "XTZ"
			tokenToIconImage = UIImage.tezosToken()
			tokenToIconURL = nil
			tokenToBalanceText = "Balance: \(xtzBalance.normalisedRepresentation)"
			
			let marketRate = DexCalculationService.shared.tokenToXtzMarketRate(xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount())
			exchangeRateText = "1 \(exchange.token.symbol) = \(marketRate ?? 0) tez"
		}
	}
	
	func refreshExchangeRates(completion: @escaping (() -> Void)) {
		if !state.isLoading() {
			state = .loading
		}
		
		print("about to query")
		let walletAddress = DependencyManager.shared.selectedWalletAddress
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: walletAddress, refreshType: .refreshEverythingIfStale) { [weak self] error in
			if let err = error {
				self?.state = .failure(err, err.description)
				return
			}
			
			if let selectedExchange = TransactionService.shared.exchangeData.selectedExchangeAndToken {
				
				// Grab the updated exchange data
				DependencyManager.shared.balanceService.exchangeData.forEach { obj in
					obj.exchanges.forEach { exchange in
						if exchange.address == selectedExchange.address {
							TransactionService.shared.exchangeData.selectedExchangeAndToken = exchange
							return
						}
					}
				}
				
				self?.state = .success(nil)
			}
			
			completion()
		}
	}
	
	func calculateReturn(fromInput: String?) {
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			state = .failure(KukaiError.unknown(withString: "Can't get pair data"), "Can't get pair data")
			return
		}
		
		guard let input = fromInput, input != "" else {
			tokenFromTextfieldInput = ""
			tokenToTextfieldInput = ""
			isPreviewHidden = true
			state = .success(nil)
			return
		}
		
		if xtzToToken {
			guard let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				state = .failure(KukaiError.unknown(withString: "Invalid amount of XTZ"), "Invalid amount of XTZ")
				return
			}
			
			TransactionService.shared.exchangeData.fromAmount = xtz
			
			self.calculationResult = DexCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: exchange.name)
			exchangeRateText = "1 XTZ = \(self.calculationResult?.displayExchangeRate ?? 0) \(exchange.token.symbol)"
			
		} else {
			guard let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: 8) else {
				state = .failure(KukaiError.unknown(withString: "Invalid amount of \(exchange.token.symbol)"), "Invalid amount of \(exchange.token.symbol)")
				return
			}
			
			TransactionService.shared.exchangeData.fromAmount = token
			
			self.calculationResult = DexCalculationService.shared.calculateTokenToXTZ(tokenToSell: token, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: exchange.name)
			exchangeRateText = "1 \(exchange.token.symbol) = \(self.calculationResult?.displayExchangeRate ?? 0) XTZ"
		}
		
		tokenFromTextfieldInput = input
		tokenToTextfieldInput = self.calculationResult?.expected.normalisedRepresentation ?? ""
		
		TransactionService.shared.exchangeData.calculationResult = self.calculationResult
		TransactionService.shared.exchangeData.isXtzToToken = xtzToToken
		TransactionService.shared.exchangeData.toAmount = self.calculationResult?.expected
		TransactionService.shared.exchangeData.exchangeRateString = exchangeRateText
	}
	
	func estimate() {
		
		/*
		guard let calc = calculationResult, calc.minimum > TokenAmount.zero(), let wallet = DependencyManager.shared.selectedWallet, let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			state = .failure(KukaiError.unknown(withString: "Invalid calculation or wallet"), "Invalid calculation or wallet")
			return
		}
		
		state = .loading
		var operations: [KukaiCoreSwift.Operation] = []
		
		if xtzToToken, let xtz = XTZAmount(fromNormalisedAmount: tokenFromTextfieldInput, decimalPlaces: 6) {
			operations = OperationFactory.swapXtzToToken(withDex: exchange, xtzAmount: xtz, minTokenAmount: calc.minimum, wallet: wallet, timeout: 60 * 5)
			
		} else if let token = TokenAmount(fromNormalisedAmount: tokenFromTextfieldInput, decimalPlaces: exchange.token.decimals) {
			operations = OperationFactory.swapTokenToXTZ(withDex: exchange, tokenAmount: token, minXTZAmount: calc.minimum as? XTZAmount ?? XTZAmount.zero(), wallet: wallet, timeout: 60 * 5)
		}
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			switch result {
				case .success(let ops):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: ops)
					self?.isPreviewHidden = false
					self?.state = .success(nil)
					
				case .failure(let error):
					self?.isPreviewHidden = true
					self?.state = .failure(error, error.description)
			}
		}
		*/
	}
}
