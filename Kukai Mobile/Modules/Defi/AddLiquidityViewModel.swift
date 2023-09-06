//
//  AddLiquidityViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/08/2022.
//
/*
import UIKit
import KukaiCoreSwift

class AddLiquidityViewModel: ViewModel {
	
	var xtzBalance: XTZAmount = .zero()
	var tokenData: (token: Token, isNFT: Bool)? = nil
	var tokenBalance: TokenAmount = TokenAmount.zero()
	var calculationResult: DexAddCalculationResult? = nil
	var previousExchange: DipDupExchange? = nil
	
	var token1Title = "XTZ"
	var token1BalanceText = "Balance: 0"
	var token1Validator = TokenAmountValidator(balanceLimit: TokenAmount.zero())
	var token1IconImage: UIImage? = UIImage.tezosToken()
	var token1IconURL: URL? = nil
	var token1TextfieldInput = ""
	
	var token2Title = "..."
	var token2BalanceText = "Balance: 0"
	var token2Validator = TokenAmountValidator(balanceLimit: TokenAmount.zero())
	var token2IconImage: UIImage? = nil
	var token2IconURL: URL? = nil
	var token2TextfieldInput = ""
	
	var isAddButtonHidden = true
	
	
	func defaultToFirstAvilableTokenIfNoneSelected() {
		if TransactionService.shared.addLiquidityData.selectedExchangeAndToken == nil {
			TransactionService.shared.addLiquidityData.selectedExchangeAndToken = DependencyManager.shared.balanceService.exchangeData[0].exchanges.last
		}
	}
	
	func updateTokenInfo() {
		guard let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken else {
			return
		}
		
		previousExchange = exchange
		
		let xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		let tokenIconURL = TzKTClient.avatarURL(forToken: exchange.token.address)
		let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address)
		let tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		token1Validator = TokenAmountValidator(balanceLimit: xtzBalance)
		token1BalanceText = "Balance: \(xtzBalance.normalisedRepresentation)"
		
		token2Title = exchange.token.symbol
		token2IconURL = tokenIconURL
		token2Validator = TokenAmountValidator(balanceLimit: tokenBalance, decimalPlaces: exchange.token.decimals)
		token2BalanceText = "Balance: \(tokenBalance.normalisedRepresentation)"
	}
	
	func refreshExchangeRates(completion: @escaping (() -> Void)) {
		/*if !state.isLoading() {
			state = .loading
		}
		
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
							TransactionService.shared.addLiquidityData.selectedExchangeAndToken = exchange
							return
						}
					}
				}
				
				self?.state = .success(nil)
			}
			
			completion()
		}*/
	}
	
	func calculateReturn(input1: String?, input2: String?) {
		guard let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken else {
			state = .failure(KukaiError.unknown(withString: "Can't get pair data"), "Can't get pair data")
			return
		}
		
		if input1 == "" || input2 == "" {
			token1TextfieldInput = ""
			token2TextfieldInput = ""
			return
		}
		
		if let xtzInput = input1, let xtz = XTZAmount(fromNormalisedAmount: xtzInput, decimalPlaces: 6) {
			self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(xtz: xtz, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), totalLiquidity: exchange.totalLiquidity(), maxSlippage: 0.005, dex: exchange.name)
			
			token1TextfieldInput = xtzInput
			token2TextfieldInput = self.calculationResult?.tokenRequired.normalisedRepresentation ?? ""
			
			TransactionService.shared.addLiquidityData.token1 = xtz
			TransactionService.shared.addLiquidityData.token2 = self.calculationResult?.tokenRequired
			
		} else if let tokenInput = input2, let token = TokenAmount(fromNormalisedAmount: tokenInput, decimalPlaces: exchange.token.decimals) {
			self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(token: token, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), totalLiquidity: exchange.totalLiquidity(), maxSlippage: 0.005, dex: exchange.name)
			
			token1TextfieldInput = self.calculationResult?.tokenRequired.normalisedRepresentation ?? ""
			token2TextfieldInput = tokenInput
			
			TransactionService.shared.addLiquidityData.token1 = self.calculationResult?.tokenRequired
			TransactionService.shared.addLiquidityData.token2 = token
		}
		
		TransactionService.shared.addLiquidityData.calculationResult = self.calculationResult
	}
	
	func estimate() {
		/*guard let calc = calculationResult,
			  let wallet = DependencyManager.shared.selectedWallet,
			  let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken,
			  let xtz = XTZAmount(fromNormalisedAmount: token1TextfieldInput, decimalPlaces: 6),
			  let token = TokenAmount(fromNormalisedAmount: token2TextfieldInput, decimalPlaces: exchange.token.decimals)
		else {
			state = .failure(KukaiError.unknown(withString: "Invalid calculation or wallet"), "Invalid calculation or wallet")
			return
		}
		
		state = .loading
		let operations = OperationFactory.addLiquidity(withDex: exchange, xtz: xtz, token: token, minLiquidty: calc.minimumLiquidity, isInitialLiquidity: exchange.arePoolsEmpty(), wallet: wallet, timeout: 60 * 5)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			
			switch result {
				case .success(let ops):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: ops)
					self?.isAddButtonHidden = false
					self?.state = .success(nil)
					
				case .failure(let error):
					self?.isAddButtonHidden = true
					self?.state = .failure(error, error.description)
			}
		}*/
	}
}
*/
