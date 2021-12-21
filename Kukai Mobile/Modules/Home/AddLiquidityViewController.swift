//
//  AddLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/11/2021.
//

import UIKit
import KukaiCoreSwift

class AddLiquidityViewController: UIViewController {

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
		
		if let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken {
			baseTokenButton.setTitle("XTZ", for: .normal)
			nonBaseTokenButton.setTitle(exchange.token.symbol, for: .normal)
			
			self.addButton.isEnabled = false
		}
	}
	
	@IBAction func checkPriceTapped(_ sender: Any) {
		guard let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken,
			  let input = baseTokenTextField.text,
			  let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				  self.alert(withTitle: "Error", andMessage: "Can't get pair data")
				  return
		}
		
		self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(xtz: xtz,
																					xtzPool: exchange.xtzPoolAmount(),
																					tokenPool: exchange.tokenPoolAmount(),
																					totalLiquidity: exchange.totalLiquidity(),
																					maxSlippage: 0.5,
																					dex: exchange.name)
		
		guard let calc = self.calculationResult else {
			nonBaseTokenTextField.text = "0"
			liquidityTextField.text = "0"
			return
		}
		
		nonBaseTokenTextField.text = calc.tokenRequired.normalisedRepresentation
		liquidityTextField.text = calc.expectedLiquidity.normalisedRepresentation
		addButton.isEnabled = true
	}
	
	func liquidityDecimalsForDex(dex: TezToolDex) -> Int {
		switch dex {
			case .quipuswap:
				return 6
				
			case .liquidityBaking:
				return 0
			
			case .unknown:
				return 0
		}
	}
	
	@IBAction func addButtonTapped(_ sender: Any) {
		guard let calc = calculationResult,
			  calc.expectedLiquidity > TokenAmount.zero(),
			  let wallet = DependencyManager.shared.selectedWallet,
			  let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken,
			  let input = baseTokenTextField.text,
			  let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6)
		else {
			self.alert(withTitle: "Error", andMessage: "Invalid calculation or wallet")
			return
		}
		
		
		self.showLoadingModal(completion: nil)
		let operations = OperationFactory.addLiquidity(withDex: exchange.name,
													   xtzToDeposit: xtz,
													   tokensToDeposit: calc.tokenRequired,
													   minLiquidtyMinted: calc.minimumLiquidity,
													   tokenContract: exchange.token.address,
													   dexContract: exchange.address,
													   isInitialLiquidity: exchange.arePoolsEmpty(),
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
						
						self.hideLoadingModal(completion: nil)
					}
				
				case .failure(let error):
					self.alert(withTitle: "Error", andMessage: error.description)
					self.hideLoadingModal(completion: nil)
			}
		}
	}
}
