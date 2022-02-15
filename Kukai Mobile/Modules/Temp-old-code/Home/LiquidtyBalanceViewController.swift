//
//  LiquidtyBalanceViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import UIKit
import KukaiCoreSwift

class LiquidtyBalanceViewController: UIViewController {

	@IBOutlet weak var totalLiquidityLabel: UILabel!
	@IBOutlet weak var xtzPoolLabel: UILabel!
	@IBOutlet weak var tokenPoolLabel: UILabel!
	@IBOutlet weak var yourLqtLabel: UILabel!
	@IBOutlet weak var percentageOwnedLabel: UILabel!
	@IBOutlet weak var yourXtzLabel: UILabel!
	@IBOutlet weak var yourTokenLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func refreshTapped(_ sender: Any) {
		
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.tezosNodeClient.getLiquidityBakingData(forContract: (address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", decimalPlaces: 8)) { [weak self] result in
			self?.hideLoadingModal(completion: nil)
			
			switch result {
				case .success(let poolData):
					self?.totalLiquidityLabel.text = poolData.totalLiquidity.normalisedRepresentation
					self?.xtzPoolLabel.text = poolData.xtzPool.normalisedRepresentation
					self?.tokenPoolLabel.text = poolData.tokenPool.normalisedRepresentation
					
					/*
					if let cachedAccount = DependencyManager.shared.betterCallDevClient.cachedAccountInfo() {
						
						for token in cachedAccount.tokens {
							if token.tokenContractAddress == poolData.liquidityTokenContractAddress {
								
								self?.yourLqtLabel.text = token.balance.normalisedRepresentation
								
								if let myLqt = token.balance.toNormalisedDecimal(), let totalLqt = poolData.totalLiquidity.toNormalisedDecimal() {
									let percentage = (myLqt / totalLqt)
									
									self?.percentageOwnedLabel.text = "\( (percentage).rounded(scale: 4, roundingMode: .bankers) * 100)%"
									self?.yourXtzLabel.text = XTZAmount(fromNormalisedAmount: (poolData.xtzPool * percentage)).normalisedRepresentation
									self?.yourTokenLabel.text = TokenAmount(fromNormalisedAmount: (poolData.tokenPool * percentage), decimalPlaces: 8).normalisedRepresentation
								} else {
									self?.alert(withTitle: "Error", andMessage: "Unable to calculate percentage")
								}
							}
						}
						
						
					} else {
						self?.alert(withTitle: "Error", andMessage: "No cached BCD data, try again later")
					}
					*/
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
}
