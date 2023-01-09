//
//  RemoveLiquidityConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/08/2022.
//

import UIKit
import KukaiCoreSwift

class RemoveLiquidityConfirmViewController: UIViewController {

	@IBOutlet weak var lpToken1Icon: UIImageView!
	@IBOutlet weak var lpToken2Icon: UIImageView!
	@IBOutlet weak var lpTokenLabel: UILabel!
	@IBOutlet weak var lpTokenAmountLabel: UILabel!
	@IBOutlet weak var lpTokenBalanceLabel: UILabel!
	
	@IBOutlet weak var token1Icon: UIImageView!
	@IBOutlet weak var token1Label: UILabel!
	@IBOutlet weak var token1AmountLabel: UILabel!
	@IBOutlet weak var token1BalanceLabel: UILabel!
	
	@IBOutlet weak var token2Icon: UIImageView!
	@IBOutlet weak var token2Label: UILabel!
	@IBOutlet weak var token2AmountLabel: UILabel!
	@IBOutlet weak var token2BalanceLabel: UILabel!
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	@IBOutlet weak var feeSettingsButton: UIButton!
	@IBOutlet weak var slideButton: SlideButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		slideButton.delegate = self
		
		guard let position = TransactionService.shared.removeLiquidityData.position else {
			return
		}
		
		let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: position.exchange.token.address)
		var tokenBalanceString = "0"
		
		if let tokenData = DependencyManager.shared.balanceService.token(forAddress: position.exchange.token.address) {
			tokenBalanceString = tokenData.token.balance.normalisedRepresentation
		}
		
		
		lpToken1Icon.image = UIImage(named: "tz-logo")
		MediaProxyService.load(url: tokenIconURL, to: lpToken2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: lpToken2Icon.frame.size)
		lpTokenLabel.text = "XTZ/\(position.exchange.token.symbol)"
		lpTokenAmountLabel.text = TransactionService.shared.removeLiquidityData.tokenAmount?.normalisedRepresentation ?? "0"
		lpTokenBalanceLabel.text = position.tokenAmount().normalisedRepresentation
		
		
		token1Icon.image = UIImage(named: "tz-logo")
		token1Label.text = "XTZ"
		token1AmountLabel.text = TransactionService.shared.removeLiquidityData.calculationResult?.expectedXTZ.normalisedRepresentation ?? ""
		token1BalanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) tez"
		
		
		MediaProxyService.load(url: tokenIconURL, to: token2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: token2Icon.frame.size)
		token2Label.text = position.exchange.token.symbol
		token2AmountLabel.text = TransactionService.shared.removeLiquidityData.calculationResult?.expectedToken.normalisedRepresentation ?? ""
		token2BalanceLabel.text = "Balance: \(tokenBalanceString) \(position.exchange.token.symbol)"
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateFees()
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
}

extension RemoveLiquidityConfirmViewController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		self.updateFees()
	}
}

extension RemoveLiquidityConfirmViewController: SlideButtonDelegate {
	
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
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
}
