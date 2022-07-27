//
//  SwapConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/07/2022.
//

import UIKit
import KukaiCoreSwift

class SwapConfirmViewController: UIViewController {

	@IBOutlet weak var tokenFromIcon: UIImageView!
	@IBOutlet weak var tokenFromLabel: UILabel!
	@IBOutlet weak var tokenFromAmountLabel: UILabel!
	@IBOutlet weak var tokenFromBalanceLabel: UILabel!
	
	@IBOutlet weak var tokenToIcon: UIImageView!
	@IBOutlet weak var tokenToLabel: UILabel!
	@IBOutlet weak var tokenToAmountLabel: UILabel!
	@IBOutlet weak var tokenToBalanceLabel: UILabel!
	@IBOutlet weak var exchangeRateLabel: UILabel!
	
	@IBOutlet weak var viewDetailsSapcingView: UIView!
	@IBOutlet weak var viewDetailsSection1: UIStackView!
	@IBOutlet weak var viewDetailsSection2: UIStackView!
	
	@IBOutlet weak var priceImpactLabel: UILabel!
	@IBOutlet weak var minReceivedLabel: UILabel!
	@IBOutlet weak var swapFeeLabel: UILabel!
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken,
			  let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address),
			  let calcResult = TransactionService.shared.exchangeData.calculationResult
		else {
			return
		}
		
		let settings = DexCalculationService.settings(forDex: exchange.name)
		
		if TransactionService.shared.exchangeData.isXtzToToken == true {
			tokenFromIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenFromLabel.text = "XTZ"
			tokenFromAmountLabel.text = TransactionService.shared.exchangeData.fromAmount?.normalisedRepresentation ?? ""
			tokenFromBalanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) tez"
			
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenToIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenToIcon.frame.size)
			
			tokenToLabel.text = exchange.token.symbol
			tokenToAmountLabel.text = TransactionService.shared.exchangeData.toAmount?.normalisedRepresentation ?? ""
			tokenToBalanceLabel.text = "Balance: \(tokenData.token.balance.normalisedRepresentation) \(exchange.token.symbol)"
			
			let fee = (TransactionService.shared.exchangeData.fromAmount ?? .zero()) * Decimal( (settings.fee)/100 )
			swapFeeLabel.text = "\(fee.rounded(scale: 6, roundingMode: .bankers)) tez"
			
		} else {
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenFromIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenFromIcon.frame.size)
			
			tokenFromLabel.text = exchange.token.symbol
			tokenFromAmountLabel.text = TransactionService.shared.exchangeData.fromAmount?.normalisedRepresentation ?? ""
			tokenFromBalanceLabel.text = "Balance: \(tokenData.token.balance.normalisedRepresentation) \(exchange.token.symbol)"
			
			tokenFromIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenToLabel.text = "XTZ"
			tokenToLabel.text = TransactionService.shared.exchangeData.toAmount?.normalisedRepresentation ?? ""
			tokenToLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) tez"
			
			let fee = (TransactionService.shared.exchangeData.toAmount ?? .zero()) * Decimal( (settings.fee)/100 )
			swapFeeLabel.text = "\(fee.rounded(scale: 6, roundingMode: .bankers)) tez"
		}
		
		exchangeRateLabel.text = TransactionService.shared.exchangeData.exchangeRateString
		priceImpactLabel.text = "\(calcResult.displayPriceImpact)%"
		minReceivedLabel.text = calcResult.minimum.normalisedRepresentation + " \(exchange.token.symbol)"
    }
}
