//
//  AddLiquidity2ViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/11/2021.
//

import UIKit
import KukaiCoreSwift

class AddLiquidity2ViewController: UIViewController {

	@IBOutlet weak var baseTokenButton: UIButton!
	@IBOutlet weak var baseTokenTextField: UITextField!
	@IBOutlet weak var nonBaseTokenButton: UIButton!
	@IBOutlet weak var nonBaseTokenTextField: UITextField!
	@IBOutlet weak var liquidityTextField: UITextField!
	@IBOutlet weak var checkPriceButton: UIButton!
	@IBOutlet weak var addButton: UIButton!
	
	private var calculationResult: DexAddCalculationResult? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		TransactionService.shared.currentTransactionType = .addLiquidity
		
		if let pair = TransactionService.shared.addLiquidityData.selectedPair {
			baseTokenButton.setTitle(pair.baseTokenSide()?.symbol, for: .normal)
			nonBaseTokenButton.setTitle(pair.nonBaseTokenSide()?.symbol, for: .normal)
			
			self.addButton.isEnabled = false
		}
	}
	
	@IBAction func checkPriceTapped(_ sender: Any) {
		guard let pair = TransactionService.shared.addLiquidityData.selectedPair,
			  let price = TransactionService.shared.addLiquidityData.selectedPrice,
			  let baseToken = pair.baseTokenSide(),
			  let nonBaseToken = pair.nonBaseTokenSide(),
			  let input = baseTokenTextField.text,
			  let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				  self.alert(withTitle: "Error", andMessage: "Can't get pair data")
				  return
		}
		
		let xtzPool = XTZAmount(fromNormalisedAmount: baseToken.pool)
		let tokenPool = TokenAmount(fromNormalisedAmount: nonBaseToken.pool, decimalPlaces: price.decimals)
		
		self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(xtz: xtz, xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: pair.liquiditySupply(decimals: price.decimals), maxSlippage: 0.5, dex: pair.dex)
		
		guard let calc = self.calculationResult else {
			nonBaseTokenTextField.text = "0"
			liquidityTextField.text = "0"
			return
		}
		
		nonBaseTokenTextField.text = calc.tokenRequired.normalisedRepresentation
		liquidityTextField.text = calc.expectedLiquidity.normalisedRepresentation
		addButton.isEnabled = true
	}
	
	@IBAction func addButtonTapped(_ sender: Any) {
		guard let calc = calculationResult,
			  calc.expectedLiquidity > TokenAmount.zero(),
			  let wallet = DependencyManager.shared.selectedWallet,
			  let pair = TransactionService.shared.addLiquidityData.selectedPair,
			  let price = TransactionService.shared.addLiquidityData.selectedPrice,
			  let input = baseTokenTextField.text,
			  let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6)
		else {
			self.alert(withTitle: "Error", andMessage: "Invalid calculation or wallet")
			return
		}
		
		
		self.showActivity(clearBackground: false)
		let operations = OperationFactory.addLiquidity(withDex: pair.dex,
													   xtzToDeposit: xtz,
													   tokensToDeposit: calc.tokenRequired,
													   minLiquidtyMinted: calc.minimumLiquidity,
													   tokenContract: price.tokenAddress,
													   dexContract: pair.address,
													   isInitialLiquidity: pair.arePoolsEmpty(),
													   wallet: wallet,
													   timeout: 60 * 5)
		
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
						
						self.hideActivity()
					}
				
				case .failure(let error):
					self.alert(withTitle: "Error", andMessage: error.description)
					self.hideActivity()
			}
		}
	}
}
