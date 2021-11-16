//
//  SwapViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/11/2021.
//

import UIKit
import KukaiCoreSwift

class SwapViewController: UIViewController {
	
	@IBOutlet weak var fromTokenButton: UIButton!
	@IBOutlet weak var fromTokentextField: UITextField!
	@IBOutlet weak var toTokenButton: UIButton!
	@IBOutlet weak var toTokenTextField: UITextField!
	@IBOutlet weak var invertTokensButton: UIButton!
	@IBOutlet weak var checkPriceButton: UIButton!
	@IBOutlet weak var swapButton: UIButton!
	
	private var isXtzToToken = true
	private var calculationResult: DexSwapCalculationResult? = nil
	
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.invertTokensButton.isEnabled = false
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		TransactionService.shared.currentTransactionType = .exchange
		
		
		if let pair = TransactionService.shared.exchangeData.selectedPair {
			fromTokenButton.setTitle(pair.baseTokenSide()?.symbol, for: .normal)
			toTokenButton.setTitle(pair.nonBaseTokenSide()?.symbol, for: .normal)
			self.invertTokensButton.isEnabled = true
			
			if fromTokenButton.title(for: .normal) == "XTZ" {
				isXtzToToken = true
			} else {
				isXtzToToken = false
			}
			
			self.swapButton.isEnabled = false
		}
	}
	
	@IBAction func fromTokenTapped(_ sender: Any) {
	}
	
	@IBAction func toTokenTapped(_ sender: Any) {
	}
	
	@IBAction func invertTokensTapped(_ sender: Any) {
		let temp = fromTokenButton.title(for: .normal)
		fromTokenButton.setTitle(toTokenButton.title(for: .normal), for: .normal)
		toTokenButton.setTitle(temp, for: .normal)
		
		if fromTokenButton.title(for: .normal) == "XTZ" {
			isXtzToToken = true
		} else {
			isXtzToToken = false
		}
	}
	
	@IBAction func checkPriceTapped(_ sender: Any) {
		guard let pair = TransactionService.shared.exchangeData.selectedPair,
			  let price = TransactionService.shared.exchangeData.selectedPrice,
			  let baseToken = pair.baseTokenSide(),
			  let nonBaseToken = pair.nonBaseTokenSide() else {
				  self.alert(withTitle: "Error", andMessage: "Can't get pair data")
				  return
		}
		
		let xtzPool = XTZAmount(fromNormalisedAmount: baseToken.pool)
		let tokenPool = TokenAmount(fromNormalisedAmount: nonBaseToken.pool, decimalPlaces: price.decimals)
		
		
		if isXtzToToken {
			guard let input = fromTokentextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5, dex: pair.dex)
			
		} else {
			guard let input = fromTokentextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: 8) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexCalculationService.shared.calculateTokenToXTZ(tokenToSell: token, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5, dex: pair.dex)
		}
		
		
		guard let calc = self.calculationResult else {
			toTokenTextField.text = "0"
			return
		}
		
		toTokenTextField.text = calc.expected.normalisedRepresentation
		swapButton.isEnabled = true
	}
	
	@IBAction func swapButtonTapped(_ sender: Any) {
		guard let calc = calculationResult,
			  calc.minimum > TokenAmount.zero(),
			  let wallet = DependencyManager.shared.selectedWallet,
			  let pair = TransactionService.shared.exchangeData.selectedPair,
			  let price = TransactionService.shared.exchangeData.selectedPrice
		else {
			self.alert(withTitle: "Error", andMessage: "Invalid calculation or wallet")
			return
		}
		
		if isXtzToToken, let input = fromTokentextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) {
			self.showActivity(clearBackground: false)
			
			let operations = OperationFactory.swapXtzToToken(withdex: pair.dex, xtzAmount: xtz, minTokenAmount: calc.minimum, dexContract: pair.address, wallet: wallet, timeout: 60 * 5)
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
		} else if let input = fromTokentextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: price.decimals) {
			self.showActivity(clearBackground: false)
			
			let operations = OperationFactory.swapTokenToXTZ(withDex: pair.dex,
															 tokenAmount: token,
															 minXTZAmount: calc.minimum as? XTZAmount ?? XTZAmount.zero(),
															 dexContract: pair.address,
															 tokenContract: price.tokenAddress,
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
		} else {
			self.alert(withTitle: "Error", andMessage: "Check the price before trying to swap")
		}
	}
}
