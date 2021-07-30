//
//  ExchangeLiquidityBakingViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2021.
//

import UIKit
import KukaiCoreSwift

class ExchangeLiquidityBakingViewController: UIViewController {

	@IBOutlet weak var inputTextField: UITextField!
	@IBOutlet weak var outputTextField: UITextField!
	@IBOutlet weak var swapButton: UIButton!
	
	@IBInspectable var isXtzToToken: Bool = true
	
	private var poolData: (xtzPool: XTZAmount, tokenPool: TokenAmount)? = nil
	private var xtzToSwap: XTZAmount? = nil
	private var tokenToSwap: TokenAmount? = nil
	private var calculationResult: DexterCalculationResult? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		inputTextField.addDoneToolbar()
    }
	
	@IBAction func checkPriceTapped(_ sender: Any) {
		DependencyManager.shared.tezosNodeClient.getLiquidityBakingPoolData(forContract: (address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", decimalPlaces: 8)) { [weak self] result in
			switch result {
				case .success(let poolData):
					self?.poolData = poolData
					self?.calculateReturn()
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
	
	@IBAction func swapButton(_ sender: Any) {
		guard let calc = calculationResult, calc.minimum > TokenAmount.zero(), let wallet = DependencyManager.shared.selectedWallet else {
			return
		}
		
		
		if isXtzToToken, let xtz = xtzToSwap {
			
			let operations = OperationFactory.liquidityBakingXtzToToken(xtzAmount: xtz, minTokenAmount: calc.minimum, contract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", wallet: wallet, timeout: 60 * 5)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { result in
				switch result {
					case .success(let ops):
						
						DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { innerResult in
							switch innerResult {
								case .success(let opHash):
									self.alert(withTitle: "Success", andMessage: "Op hash: \(opHash)")
									
								case .failure(let error):
									self.alert(withTitle: "Error", andMessage: error.description)
							}
						}
					
					case .failure(let error):
						self.alert(withTitle: "Error", andMessage: error.description)
				}
			}
			
		} else if let token = tokenToSwap {
			let operations = OperationFactory.liquidityBakingTokenToXTZ(
				tokenAmount: token,
				minXTZAmount: calc.minimum as? XTZAmount ?? XTZAmount.zero(),
				contract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5",
				tokenContract: "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN",
				currentAllowance: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0),
				wallet: wallet,
				timeout: 60 * 5
			)
			
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { result in
				switch result {
					case .success(let ops):
						
						DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { innerResult in
							switch innerResult {
								case .success(let opHash):
									self.alert(withTitle: "Success", andMessage: "Op hash: \(opHash)")
									
								case .failure(let error):
									self.alert(withTitle: "Error", andMessage: error.description)
							}
						}
					
					case .failure(let error):
						self.alert(withTitle: "Error", andMessage: error.description)
				}
			}
		}
	}
	
	func calculateReturn() {
		guard let pData = poolData else {
			self.alert(withTitle: "Error", andMessage: "Please refresh the pool data first, to estimate return")
			return
		}
		
		if isXtzToToken {
			guard let input = inputTextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexterCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, dexterXtzPool: pData.xtzPool, dexterTokenPool: pData.tokenPool, maxSlippage: 0.5)
			
		} else {
			guard let input = inputTextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: 8) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexterCalculationService.shared.calcualteTokenToXTZ(tokenToSell: token, dexterXtzPool: pData.xtzPool, dexterTokenPool:  pData.tokenPool, maxSlippage: 0.5)
		}
		
		
		guard let calc = self.calculationResult else {
			outputTextField.text = "0"
			return
		}
		
		outputTextField.text = calc.expected.normalisedRepresentation
	}
}
