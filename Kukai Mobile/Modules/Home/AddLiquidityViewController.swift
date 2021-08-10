//
//  AddLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import UIKit
import KukaiCoreSwift

class AddLiquidityViewController: UIViewController {

	@IBOutlet weak var xtzTextField: UITextField!
	@IBOutlet weak var tzbtcTextField: UITextField!
	@IBOutlet weak var liquidityTextField: UITextField!
	
	private var poolData: LiquidityBakingData? = nil
	private var xtzToDeposit: XTZAmount? = nil
	private var tokenToDeposit: TokenAmount? = nil
	private var calculationResult: LiquidityBakingAddCalculationResult? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		xtzTextField.addDoneToolbar()
    }
	
	@IBAction func refreshButtonTapped(_ sender: Any) {
		guard let xtzText = xtzTextField.text, let xtz = XTZAmount(fromNormalisedAmount: xtzText, decimalPlaces: 6) else {
			self.alert(withTitle: "Error", andMessage: "Invalid XTZ amount")
			return
		}
		
		xtzToDeposit = xtz
		
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
		guard let pData = poolData else {
			self.alert(withTitle: "Error", andMessage: "Please refresh the pool data first, to estimate return")
			return
		}
			
		calculationResult = LiquidityBakingCalculationService.shared.calculateAddLiquidity(xtz: xtzToDeposit ?? XTZAmount.zero(), xtzPool: pData.xtzPool, tokenPool: pData.tokenPool, totalLiquidity: pData.totalLiquidity, maxSlippage: 0.05)
		
		guard let calc = self.calculationResult else {
			tzbtcTextField.text = "0"
			liquidityTextField.text = "0"
			return
		}
		
		tzbtcTextField.text = calc.tokenRequired.normalisedRepresentation
		liquidityTextField.text = calc.expectedLiquidity.normalisedRepresentation
	}
	
	@IBAction func swapButtonTapped(_ sender: Any) {
		guard let calc = calculationResult, calc.tokenRequired > TokenAmount.zero(), calc.expectedLiquidity > TokenAmount.zero(), let wallet = DependencyManager.shared.selectedWallet, let xtz = xtzToDeposit else {
			self.alert(withTitle: "Error", andMessage: "Invalid calcualtion or wallet")
			return
		}
		
		self.showActivity(clearBackground: false)
		
		let operations = OperationFactory.liquidityBakingAddLiquidity(xtzToDeposit: xtz, tokensToDeposit: calc.tokenRequired, minLiquidtyMinted: calc.minimumLiquidity, tokenContract: poolData?.tokenContractAddress ?? "", dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", currentAllowance: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0), wallet: wallet, timeout: 60 * 5)
		
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
}
