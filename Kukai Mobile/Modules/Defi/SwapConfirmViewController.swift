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
	
	@IBOutlet weak var viewDetailsButton: UIButton!
	@IBOutlet weak var viewDetailsSapcingView: UIView!
	@IBOutlet weak var viewDetailsSection1: UIStackView!
	@IBOutlet weak var viewDetailsSection2: UIStackView!
	
	@IBOutlet weak var priceImpactLabel: UILabel!
	@IBOutlet weak var minReceivedLabel: UILabel!
	@IBOutlet weak var swapFeeLabel: UILabel!
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	
	@IBOutlet weak var slideButton: SlideButton!
	
	
	private var isDetailsOpen = false
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		slideButton.delegate = self
		showDetails(false, animated: false)
		
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken,
			  let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address),
			  let calcResult = TransactionService.shared.exchangeData.calculationResult,
			  let ops = TransactionService.shared.exchangeData.operations
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
			
			minReceivedLabel.text = calcResult.minimum.normalisedRepresentation + " \(exchange.token.symbol)"
			
		} else {
			
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenFromIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenFromIcon.frame.size)
			
			tokenFromLabel.text = exchange.token.symbol
			tokenFromAmountLabel.text = TransactionService.shared.exchangeData.fromAmount?.normalisedRepresentation ?? ""
			tokenFromBalanceLabel.text = "Balance: \(tokenData.token.balance.normalisedRepresentation) \(exchange.token.symbol)"
			
			tokenToIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenToLabel.text = "XTZ"
			tokenToAmountLabel.text = TransactionService.shared.exchangeData.toAmount?.normalisedRepresentation ?? ""
			tokenToBalanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) tez"
			
			let fee = (TransactionService.shared.exchangeData.toAmount ?? .zero()) * Decimal( (settings.fee)/100 )
			swapFeeLabel.text = "\(fee.rounded(scale: 6, roundingMode: .bankers)) tez"
			
			minReceivedLabel.text = calcResult.minimum.normalisedRepresentation + " tez"
		}
		
		exchangeRateLabel.text = TransactionService.shared.exchangeData.exchangeRateString
		priceImpactLabel.text = "\(calcResult.displayPriceImpact)%"
		
		let totalFee = ops.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +)
		let totalStorage = ops.map({ $0.operationFees.allNetworkFees() }).reduce(XTZAmount.zero(), +)
		feeLabel.text = totalFee.normalisedRepresentation + " xtz"
		storageCostLabel.text = totalStorage.normalisedRepresentation + " xtz"
    }
	
	@IBAction func viewDetailsTapped(_ sender: Any) {
		showDetails(!isDetailsOpen, animated: true)
	}
	
	
	
	// MARK: - Helpers
	
	func showDetails(_ show: Bool, animated: Bool) {
		isDetailsOpen = show
		
		viewDetailsSapcingView.isHidden = !show
		viewDetailsSection1.isHidden = !show
		viewDetailsSection2.isHidden = !show
		
		if show {
			viewDetailsButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
		} else {
			viewDetailsButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
		}
		
		if animated {
			UIView.animate(withDuration: 0.3) {
				self.view.layoutIfNeeded()
			}
		}
	}
}

extension SwapConfirmViewController: SlideButtonDelegate {
	
	func didCompleteSlide() {
		self.alert(withTitle: "Boom!", andMessage: "Diddy")
	}
}
