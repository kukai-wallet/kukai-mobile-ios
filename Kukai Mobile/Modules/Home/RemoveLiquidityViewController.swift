//
//  RemoveLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import UIKit
import KukaiCoreSwift

class RemoveLiquidityViewController: UIViewController {

	@IBOutlet weak var liquidityTextField: UITextField!
	@IBOutlet weak var xtzTextField: UITextField!
	@IBOutlet weak var tzbtcTextField: UITextField!
	
	/*
	private var poolData: LiquidityBakingData? = nil
	private var liquidityToBurn: TokenAmount? = nil
	private var calculationResult: LiquidityBakingRemoveCalculationResult? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		liquidityTextField.addDoneToolbar()
    }

	@IBAction func refreshButtonTapped(_ sender: Any) {
		guard let lqtText = liquidityTextField.text, let lqt = TokenAmount(fromNormalisedAmount: lqtText, decimalPlaces: 0) else {
			self.alert(withTitle: "Error", andMessage: "Invalid Liquidity amount")
			return
		}
		
		liquidityToBurn = lqt
		
		DependencyManager.shared.tezosNodeClient.getLiquidityBakingData(forContract: (address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", decimalPlaces: 8)) { [weak self] result in
			switch result {
				case .success(let poolData):
					self?.poolData = poolData
					self?.calculateReturn()
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
	
	func calculateReturn() {
		/*guard let pData = poolData else {
			self.alert(withTitle: "Error", andMessage: "Please refresh the pool data first, to estimate return")
			return
		}
			
		calculationResult = LiquidityBakingCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: liquidityToBurn ?? TokenAmount.zero(), totalLiquidity: pData.totalLiquidity, xtzPool: pData.xtzPool, tokenPool: pData.tokenPool, maxSlippage: 0.05)
		
		guard let calc = self.calculationResult else {
			tzbtcTextField.text = "0"
			liquidityTextField.text = "0"
			return
		}
		
		xtzTextField.text = calc.expectedXTZ.normalisedRepresentation
		tzbtcTextField.text = calc.expectedToken.normalisedRepresentation*/
	}
	 
	@IBAction func removeTapped(_ sender: Any) {
		guard let calc = calculationResult, calc.minimumXTZ > TokenAmount.zero(), calc.minimumToken > TokenAmount.zero(), let wallet = DependencyManager.shared.selectedWallet, let lqt = liquidityToBurn else {
			self.alert(withTitle: "Error", andMessage: "Invalid calcualtion or wallet")
			return
		}
		
		self.showActivity(clearBackground: false)
		
		let operations = OperationFactory.liquidityBakingRemoveLiquidity(minXTZ: calc.minimumXTZ, minToken: calc.minimumToken, liquidityToBurn: lqt, dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", wallet: wallet, timeout: 60 * 5)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { result in
			switch result {
				case .success(let ops):
					
					DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { innerResult in
						switch innerResult {
							case .success(let opHash):
								self.alert(withTitle: "Success", andMessage: "opHash: \(opHash)")
								
								
							case .failure(let error):
								self.alert(withTitle: "Error", andMessage: error.description)
						}
						
						self.hideActivity()
					}
				
				case .failure(let error):
					self.alert(withTitle: "Error", andMessage: error.description)
					self.hideActivity()
			}
		}
	}
	*/
}
