//
//  ConfirmStakeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift
import os.log

class ConfirmStakeViewController: UIViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var confirmBakerAddView: UIView!
	@IBOutlet weak var bakerAddIcon: UIImageView!
	@IBOutlet weak var bakerAddNameLabel: UILabel!
	@IBOutlet weak var bakerAddSplitLabel: UILabel!
	@IBOutlet weak var bakerAddSpaceLabel: UILabel!
	@IBOutlet weak var bakerAddEstimatedRewardLabel: UILabel!
	
	@IBOutlet weak var confirmBakerRemoveView: UIView!
	@IBOutlet weak var bakerRemoveIcon: UIImageView!
	@IBOutlet weak var bakerRemoveNameLabel: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var currentDelegateData: TransactionService.DelegateData = TransactionService.DelegateData()
	private var selectedMetadata: WalletMetadata? = nil
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		if DependencyManager.shared.currentNetworkType != .testnet {
			testnetWarningView.isHidden = true
		}
		
		self.currentDelegateData = TransactionService.shared.delegateData
		self.selectedMetadata = DependencyManager.shared.selectedWalletMetadata
		
		guard let baker = self.currentDelegateData.chosenBaker else {
			return
		}
		
		
		// Baker info config
		if self.currentDelegateData.isAdd == true {
			confirmBakerRemoveView.isHidden = true
			
			bakerAddNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
			if baker.name == nil && baker.fee == 0 && baker.stakingCapacity == 0 && baker.estimatedRoi == 0 {
				bakerAddSplitLabel.text = "N/A"
				bakerAddSpaceLabel.text = "N/A"
				bakerAddEstimatedRewardLabel.text = "N/A"
				
			} else {
				bakerAddSplitLabel.text = (Decimal(baker.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
				bakerAddSpaceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.freeSpace, decimalPlaces: 0) + " tez"
				bakerAddEstimatedRewardLabel.text = (baker.estimatedRoi * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			}
			
		} else {
			confirmBakerAddView.isHidden = true
			bakerRemoveNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		}
		
		
		// Fees and amount view config
		feeButton.customButtonType = .secondary
		updateFees()
		
		
		// Ledger check
		if selectedMetadata?.type != .ledger {
			ledgerWarningLabel.isHidden = true
		}
		
		
		// Error / warning check (TBD)
		errorLabel.isHidden = true
		
		
		if ledgerWarningLabel.isHidden && errorLabel.isHidden {
			slideErrorStackView.isHidden = true
		}
		
		slideButton.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let _ = containerView.addGradientPanelRows(withFrame: containerView.bounds)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let baker = self.currentDelegateData.chosenBaker else {
			self.alert(errorWithMessage: "Unable to process baker")
			self.dismissBottomSheet()
			return
		}
		
		if self.currentDelegateData.isAdd == true {
			MediaProxyService.load(url: URL(string: baker.logo ?? ""), to: bakerAddIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
			
		} else {
			MediaProxyService.load(url: URL(string: baker.logo ?? ""), to: bakerRemoveIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.hideLoadingView()
	}
	
	private func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
		return TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
	}
	
	func didCompleteSlide() {
		self.showLoadingModal(invisible: true)
		
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(invisible: true, completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default, opHash)
						
						self?.addPendingTransaction(opHash: opHash)
						self?.dismissAndReturn()
						
					case .failure(let sendError):
						self?.alert(errorWithMessage: sendError.description)
						self?.slideButton?.resetSlider()
				}
			})
		}
	}
	
	func updateFees() {
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		feeValueLabel.text = fee.normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	func dismissAndReturn() {
		TransactionService.shared.resetAllState()
		
		self.dismiss(animated: true, completion: nil)
		(self.presentingViewController as? UINavigationController)?.popToHome()
	}
	
	func addPendingTransaction(opHash: String) {
		guard let selectedWalletMetadata = selectedMetadata, let baker = TransactionService.shared.delegateData.chosenBaker else { return }
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash, type: .delegation, counter: counter, fromWallet: selectedWalletMetadata, newDelegate: TzKTAddress(alias: baker.name, address: baker.address))
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		os_log("Recorded pending transaction: %@", "\(addPendingResult)")
	}
}

extension ConfirmStakeViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		view.setNeedsLayout()
		view.layoutIfNeeded()
		
		return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
	}
}
