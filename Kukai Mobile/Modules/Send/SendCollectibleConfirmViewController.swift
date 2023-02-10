//
//  SendCollectibleConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/02/2023.
//

import UIKit
import KukaiCoreSwift
import OSLog

class SendCollectibleConfirmViewController: UIViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet weak var collectibleImage: UIImageView!
	@IBOutlet weak var collectibleNameLabel: UILabel!
	@IBOutlet weak var quantityStackView: UIStackView!
	@IBOutlet weak var collectibleQuantityLabel: UILabel!
	
	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var socialIcon: UIImageView!
	@IBOutlet weak var socialAlias: UILabel!
	@IBOutlet weak var socialAddress: UILabel!
	
	@IBOutlet weak var toStackViewRegular: UIStackView!
	@IBOutlet weak var regularAddress: UILabel!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		guard let token = TransactionService.shared.sendData.chosenNFT, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		
		// Token data
		collectibleNameLabel.text = token.name
		let quantityString = amount.normalisedRepresentation
		if quantityString == "1" {
			quantityStackView.isHidden = true
		} else {
			quantityStackView.isHidden = false
			collectibleQuantityLabel.text = quantityString
		}
		
		feeValueLabel?.text = "0 tez"
		MediaProxyService.load(url: MediaProxyService.url(fromUri: token.displayURI, ofFormat: .small), to: collectibleImage, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: collectibleImage.frame.size)
		
		
		
		// Destination view configuration
		if let alias = TransactionService.shared.sendData.destinationAlias {
			// social display
			toStackViewRegular.isHidden = true
			socialAlias.text = alias
			socialIcon.image = TransactionService.shared.sendData.destinationIcon
			socialAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			
		} else {
			// basic display
			toStackViewSocial.isHidden = true
			regularAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
		}
		
		
		// Fees
		updateFees()
		feeButton.configuration?.imagePlacement = .trailing
		feeButton.configuration?.imagePadding = 6
		
		
		// Ledger check
		if DependencyManager.shared.selectedWalletMetadata.type != .ledger {
			ledgerWarningLabel.isHidden = true
		}
		
		
		// Error / warning check (TBD)
		errorLabel.isHidden = true
		
		slideButton.delegate = self
    }
	
	func didCompleteSlide() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Confirmed!")
			
			self?.hideLoadingModal(completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default,  opHash)
						self?.dismiss(animated: true, completion: nil)
						(self?.presentingViewController as? UINavigationController)?.popToHome()
						
					case .failure(let sendError):
						self?.alert(errorWithMessage: sendError.description)
						self?.slideButton?.resetSlider()
				}
			})
		}
	}
	
	func updateFees() {
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		
		feeValueLabel.text = (feesAndData.fee + feesAndData.maxStorageCost).normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
}