//
//  RemoveLiquidityViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/08/2022.
//

import UIKit
import KukaiCoreSwift

class RemoveLiquidityViewModel: ViewModel {
	
	var xtzBalance: XTZAmount = .zero()
	var lqtTokenBalance: TokenAmount = TokenAmount.zero()
	var tokenData: (token: Token, isNFT: Bool)? = nil
	var tokenBalance: TokenAmount = TokenAmount.zero()
	var calculationResult: DexRemoveCalculationResult? = nil
	var previousPosition: DipDupPositionData? = nil
	
	var lpTokenTitle = "XTZ"
	var lpTokenBalanceText = "Balance: 0"
	var lpTokenValidator = TokenAmountValidator(balanceLimit: TokenAmount.zero())
	var lpToken1IconImage: UIImage? = UIImage.tezosToken()
	var lpToken1IconURL: URL? = nil
	var lpToken2IconImage: UIImage? = UIImage.tezosToken()
	var lpToken2IconURL: URL? = nil
	var lpTokenTextfieldInput = ""
	
	var outputToken1Title = "XTZ"
	var outputToken1BalanceText = "Balance: 0"
	var outputToken1TextfieldInput = ""
	var outputToken2Title = "XTZ"
	var outputToken2BalanceText = "Balance: 0"
	var outputToken2TextfieldInput = ""
	
	var isRemoveButtonHidden = true
	
	
	func defaultToFirstAvilableTokenIfNoneSelected() {
		if TransactionService.shared.removeLiquidityData.position == nil {
			TransactionService.shared.removeLiquidityData.position = DependencyManager.shared.balanceService.account.liquidityTokens.first
		}
	}
	
	func updateTokenInfo() {
		guard let position = TransactionService.shared.removeLiquidityData.position else {
			return
		}
		
		previousPosition = position
		lqtTokenBalance = position.tokenAmount()
		xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		tokenData = DependencyManager.shared.balanceService.token(forAddress: position.exchange.token.address)
		tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		let tokenIconURL = TzKTClient.avatarURL(forToken: position.exchange.token.address)
		
		lpTokenTitle = "XTZ/\(position.exchange.token.symbol)"
		lpTokenBalanceText = "Balance: \(lqtTokenBalance.normalisedRepresentation)"
		lpTokenValidator = TokenAmountValidator(balanceLimit: lqtTokenBalance, decimalPlaces: lqtTokenBalance.decimalPlaces)
		lpToken1IconImage = UIImage.tezosToken()
		lpToken1IconURL = nil
		lpToken2IconImage = nil
		lpToken2IconURL = tokenIconURL
		lpTokenTextfieldInput = ""
		
		outputToken1Title = "XTZ"
		outputToken1BalanceText = "Balance: \(xtzBalance.normalisedRepresentation)"
		outputToken1TextfieldInput = ""
		outputToken2Title = position.exchange.token.symbol
		outputToken2BalanceText = "Balance: \(tokenBalance.normalisedRepresentation)"
		outputToken2TextfieldInput = ""
	}
	
	func refreshExchangeRates(completion: @escaping (() -> Void)) {
		if !state.isLoading() {
			state = .loading
		}
		
		let walletAddress = DependencyManager.shared.selectedWalletAddress
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: walletAddress, refreshType: .refreshEverythingIfStale) { [weak self] error in
			if let err = error {
				self?.state = .failure(err, err.description)
				return
			}
			
			if let selectedPosition = TransactionService.shared.removeLiquidityData.position {
				
				// Grab the updated exchange data
				DependencyManager.shared.balanceService.account.liquidityTokens.forEach { obj in
					if obj.exchange.address == selectedPosition.exchange.address {
						TransactionService.shared.removeLiquidityData.position = obj
						return
					}
				}
				
				self?.state = .success(nil)
			}
			
			completion()
		}
	}
	
	func calculateReturn(fromInput: String?) {
		guard let position = TransactionService.shared.removeLiquidityData.position else {
			state = .failure(KukaiError.unknown(withString: "Can't get pair data"), "Can't get pair data")
			return
		}
		
		guard let input = fromInput, input != "" else {
			lpTokenTextfieldInput = ""
			outputToken1TextfieldInput = ""
			outputToken2TextfieldInput = ""
			state = .success(nil)
			return
		}
		
		let lqtTokenAmount = TokenAmount(fromNormalisedAmount: input, decimalPlaces: position.exchange.liquidityTokenDecimalPlaces()) ?? TokenAmount.zero()
		self.calculationResult = DexCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: lqtTokenAmount, totalLiquidity: position.exchange.totalLiquidity(), xtzPool: position.exchange.xtzPoolAmount(), tokenPool: position.exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: position.exchange.name)
		
		lpTokenTextfieldInput = input
		outputToken1TextfieldInput = self.calculationResult?.expectedXTZ.normalisedRepresentation ?? ""
		outputToken2TextfieldInput = self.calculationResult?.expectedToken.normalisedRepresentation ?? ""
		
		TransactionService.shared.removeLiquidityData.tokenAmount = lqtTokenAmount
		TransactionService.shared.removeLiquidityData.calculationResult = self.calculationResult
	}
	
	func estimate() {
		/*guard let calc = calculationResult, calc.expectedToken > TokenAmount.zero(),
			  let wallet = DependencyManager.shared.selectedWallet,
			  let position = TransactionService.shared.removeLiquidityData.position,
			  let lpTokenAmount = TokenAmount(fromNormalisedAmount: lpTokenTextfieldInput, decimalPlaces: position.exchange.liquidityTokenDecimalPlaces())
		else {
			state = .failure(KukaiError.unknown(withString: "Invalid calculation or wallet"), "Invalid calculation or wallet")
			return
		}
		
		state = .loading
		let operations = OperationFactory.removeLiquidity(withDex: position.exchange, minXTZ: calc.minimumXTZ, minToken: calc.minimumToken, liquidityToBurn: lpTokenAmount, wallet: wallet, timeout: 60 * 5)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			switch result {
				case .success(let ops):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: ops)
					self?.isRemoveButtonHidden = false
					self?.state = .success(nil)
					
				case .failure(let error):
					self?.isRemoveButtonHidden = true
					self?.state = .failure(error, error.description)
			}
		}*/
	}
}
