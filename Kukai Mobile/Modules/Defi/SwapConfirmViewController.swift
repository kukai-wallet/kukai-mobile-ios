//
//  SwapConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/07/2022.
//

/*
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
	@IBOutlet weak var feeSettingsButton: UIButton!
	
	@IBOutlet weak var slideButton: SlideButton!
	
	
	private var isDetailsOpen = false
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		slideButton.delegate = self
		showDetails(false, animated: false)
		
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken,
			  let calcResult = TransactionService.shared.exchangeData.calculationResult
		else {
			return
		}
		
		var tokenBalanceString = "0"
		if let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address) {
			tokenBalanceString =  tokenData.token.balance.normalisedRepresentation
		}
		let settings = DexCalculationService.settings(forDex: exchange.name)
		
		if TransactionService.shared.exchangeData.isXtzToToken == true {
			tokenFromIcon.image = UIImage.tezosToken()
			tokenFromLabel.text = "XTZ"
			tokenFromAmountLabel.text = TransactionService.shared.exchangeData.fromAmount?.normalisedRepresentation ?? ""
			tokenFromBalanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) XTZ"
			
			let tokenIconURL = TzKTClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenToIcon, withCacheType: .permanent, fallback: UIImage())
			
			tokenToLabel.text = exchange.token.symbol
			tokenToAmountLabel.text = TransactionService.shared.exchangeData.toAmount?.normalisedRepresentation ?? ""
			tokenToBalanceLabel.text = "Balance: \(tokenBalanceString) \(exchange.token.symbol)"
			
			let fee = (TransactionService.shared.exchangeData.fromAmount ?? .zero()) * Decimal( (settings.fee)/100 )
			swapFeeLabel.text = "\(fee.rounded(scale: 6, roundingMode: .bankers)) XTZ"
			
			minReceivedLabel.text = calcResult.minimum.normalisedRepresentation + " \(exchange.token.symbol)"
			
		} else {
			
			let tokenIconURL = TzKTClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenFromIcon, withCacheType: .permanent, fallback: UIImage())
			
			tokenFromLabel.text = exchange.token.symbol
			tokenFromAmountLabel.text = TransactionService.shared.exchangeData.fromAmount?.normalisedRepresentation ?? ""
			tokenFromBalanceLabel.text = "Balance: \(tokenBalanceString) \(exchange.token.symbol)"
			
			tokenToIcon.image = UIImage.tezosToken()
			tokenToLabel.text = "XTZ"
			tokenToAmountLabel.text = TransactionService.shared.exchangeData.toAmount?.normalisedRepresentation ?? ""
			tokenToBalanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) XTZ"
			
			let fee = (TransactionService.shared.exchangeData.toAmount ?? .zero()) * Decimal( (settings.fee)/100 )
			swapFeeLabel.text = "\(fee.rounded(scale: 6, roundingMode: .bankers)) XTZ"
			
			minReceivedLabel.text = calcResult.minimum.normalisedRepresentation + " XTZ"
		}
		
		exchangeRateLabel.text = TransactionService.shared.exchangeData.exchangeRateString
		priceImpactLabel.text = "\(calcResult.displayPriceImpact)%"
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateFees()
	}
	
	@IBAction func viewDetailsTapped(_ sender: Any) {
		showDetails(!isDetailsOpen, animated: true)
	}
	
	func updateFees() {
		feeLabel.text = TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation + " xtz"
		storageCostLabel.text = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation + " xtz"
		feeSettingsButton.setTitle(TransactionService.shared.currentOperationsAndFeesData.type.displayName(), for: .normal)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let dest = segue.destination.presentationController as? UISheetPresentationController else {
			return
		}
		
		dest.delegate = self
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

extension SwapConfirmViewController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		self.updateFees()
	}
}

extension SwapConfirmViewController: SlideButtonDelegate {
	
	func didCompleteSlide() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find operations, try again")
			return
		}
		
		self.showLoadingView()
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] innerResult in
			self?.hideLoadingView()
			
			switch innerResult {
				case .success(let opHash):
					self?.alert(withTitle: "Success", andMessage: "Op hash: \(opHash)")
					self?.navigationController?.popViewController(animated: true)
					
				case .failure(let error):
					self?.alert(withTitle: "error".localized(), andMessage: error.description)
			}
		}
	}
}
*/
