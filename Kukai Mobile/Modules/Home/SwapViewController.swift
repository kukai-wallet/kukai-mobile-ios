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
	private var calculationResult: LiquidityBakingSwapCalculationResult? = nil
	
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.invertTokensButton.isEnabled = false
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let pair = TransactionService.shared.exchangeData.selectedPair {
			fromTokenButton.setTitle(pair.baseTokenSide()?.symbol, for: .normal)
			toTokenButton.setTitle(pair.nonBaseTokenSide()?.symbol, for: .normal)
			self.invertTokensButton.isEnabled = true
			
			if fromTokenButton.title(for: .normal) == "XTZ" {
				isXtzToToken = true
			} else {
				isXtzToToken = false
			}
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
			  let pairDecimals = TransactionService.shared.exchangeData.selectedPairDecimals,
			  let baseToken = pair.baseTokenSide(),
			  let nonBaseToken = pair.nonBaseTokenSide() else {
				  self.alert(withTitle: "Error", andMessage: "Can't get pair data")
				  return
		}
		
		let xtzPool = XTZAmount(fromNormalisedAmount: baseToken.pool)
		let tokenPool = TokenAmount(fromNormalisedAmount: nonBaseToken.pool, decimalPlaces: pairDecimals)
		
		
		if isXtzToToken {
			guard let input = fromTokentextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = LiquidityBakingCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5)
			
		} else {
			guard let input = fromTokentextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: 8) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = LiquidityBakingCalculationService.shared.calculateTokenToXTZ(tokenToSell: token, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5)
		}
		
		
		guard let calc = self.calculationResult else {
			toTokenTextField.text = "0"
			return
		}
		
		toTokenTextField.text = calc.expected.normalisedRepresentation
		
	}
	
	@IBAction func swapButtonTapped(_ sender: Any) {
	}
}
