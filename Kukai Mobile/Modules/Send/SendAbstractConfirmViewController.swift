//
//  SendAbstractConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/01/2024.
//

import UIKit
import KukaiCoreSwift
import WalletConnectNetworking
import Combine
import OSLog

class SendAbstractConfirmViewController: UIViewController {
	
	public var isWalletConnectOp = false
	public var didSend = false
	
	public var connectedAppURL: URL? = nil
	public var currentSendData: TransactionService.SendData = TransactionService.SendData()
	public var currentBatchData: TransactionService.BatchData = TransactionService.BatchData()
	public var selectedMetadata: WalletMetadata? = nil
	
	private var bag = [AnyCancellable]()
	private var swipeDownEnabled = true
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		presentationController?.delegate = self
		
		/*
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.showLoadingView()
				self?.updateLoadingViewStatusLabel(message: "Please confirm the transaction on your Ledger device")
			}
			.store(in: &bag)
		*/
		
		NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] _ in
			self?.ledgerCheck()
		}.store(in: &bag)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		UIApplication.shared.isIdleTimerDisabled = true
		
		// Monitor connection
		if isWalletConnectOp {
			Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
				DispatchQueue.main.async { [weak self] in
					
					if status == .disconnected {
						self?.showLoadingModal()
						self?.updateLoadingModalStatusLabel(message: "Reconnecting ... ")
					} else {
						UIViewController.removeLoadingModal()
					}
				}
			}.store(in: &bag)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		ledgerCheck()
	}
	
	private func ledgerCheck() {
		if let meta = selectedMetadata, meta.type == .ledger {
			AccountsViewModel.askToConnectToLedgerIfNeeded(walletMetadata: meta) { success in
				if !success {
					self.dismissAndReturn(collapseOnly: true)
				}
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		UIApplication.shared.isIdleTimerDisabled = false
		
		if !didSend && isWalletConnectOp {
			handleRejection(andDismiss: false)
		}
		
		if LedgerService.shared.getConnectedDeviceUUID() != nil {
			LedgerService.shared.disconnectFromDevice()
		}
	}
	
	func dismissAndReturn(collapseOnly: Bool) {
		DispatchQueue.main.async { [weak self] in
			let topMostNavigationController = ((self?.presentationController?.presentingViewController as? UINavigationController)?.presentationController?.presentingViewController as? UINavigationController)
			let isDuringStakeOnboardingFlow = topMostNavigationController?.viewControllers.contains(where: { $0 is StakeOnboardingContainerViewController }) ?? false
			
			// Only directly dismiss the current confirmation screen if its not part of the stake onboarding flow, as that requires a special dismiss to avoid temporary screens popping up
			if !(isDuringStakeOnboardingFlow && collapseOnly == false) {
				self?.dismiss(animated: true, completion: {
					UIViewController.removeLoadingView()
					UIViewController.removeLoadingModal()
				})
			}
			
			// If we are part of stake onboarding flow we want to just dismiss the entire thing in one action. Otherwise we need two types of animations
			if collapseOnly == false {
				if isDuringStakeOnboardingFlow {
					topMostNavigationController?.dismiss(animated: true)
					
				} else {
					(self?.presentingViewController as? UINavigationController)?.popToHome()
				}
			}
		}
	}
	
	func checkForErrorsAndWarnings(errorStackView: UIStackView, errorLabel: UILabel, totalFee: XTZAmount) {
		
		if (totalFee.toNormalisedDecimal() ?? 0) > 10 {
			// Warn user that the fee is very high
			errorStackView.isHidden = false
			errorLabel.isHidden = false
			errorLabel.text = "warning-fee-very-high".localized()
			errorLabel.textColor = .colorNamed("TxtB-alt4")
		} else {
			errorStackView.isHidden = true
			errorLabel.isHidden = true
			//errorLabel.textColor = .colorNamed("TxtAlert4")
		}
	}
	
	
	
	// MARK: - WC2 functions
	
	func handleRejection(andDismiss: Bool = true, collapseOnly: Bool = false) {
		if !isWalletConnectOp {
			if andDismiss { self.dismissAndReturn(collapseOnly: collapseOnly) }
			return
		}
		
		if andDismiss { self.showLoadingView() }
		WalletConnectService.rejectCurrentRequest(completion: { [weak self] success, error in
			DispatchQueue.main.async { [weak self] in
				if andDismiss { UIViewController.removeLoadingView() }
				
				if success {
					self?.didSend = true
					if andDismiss { self?.dismissAndReturn(collapseOnly: collapseOnly) }
					
				} else {
					var message = ""
					if let err = error {
						message = err.localizedDescription
					} else {
						message = "error-wc2-unrecoverable".localized()
					}
					
					Logger.app.error("WC Rejction error: \(error)")
					self?.windowError(withTitle: "error".localized(), description: message)
					self?.dismissAndReturn(collapseOnly: collapseOnly)
				}
			}
		})
	}
	
	func handleApproval(opHash: String, slideButton: SlideButton?) {
		AccountViewModel.reconnectAccountActivityListenerIfNeeded()
		
		if !isWalletConnectOp {
			TransactionService.shared.resetAllState()
			self.dismissAndReturn(collapseOnly: false)
			return
		}
		
		WalletConnectService.approveCurrentRequest(signature: nil, opHash: opHash, completion: { [weak self] success, error in
			if success {
				
				DispatchQueue.main.async {
					slideButton?.markComplete(withText: "Complete")
				}
				
				// Delay for UX purposes only, just a brief delay to see the words "complete"
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
					self?.dismissAndReturn(collapseOnly: false)
				}
				
			} else {
				var message = "error-wc2-unrecoverable".localized()
				
				if let err = error {
					if err.localizedDescription == "Unsupported or empty accounts for namespace" {
						message = "Unsupported namespace. \nPlease check your wallet is using the same network as the application you are trying to connect to (e.g. Mainnet or Ghostnet)"
					} else {
						message = "\(err)"
					}
				}
				
				Logger.app.error("WC Approve error: \(error)")
				self?.windowError(withTitle: "error".localized(), description: message)
				self?.dismissAndReturn(collapseOnly: true)
			}
		})
	}
	
	public func blockInteraction(exceptFor: [UIView]) {
		self.swipeDownEnabled = false
		
		for view in self.view.subviews {
			if !exceptFor.contains([view]) {
				view.isUserInteractionEnabled = false
			}
		}
	}
	
	public func unblockInteraction() {
		self.swipeDownEnabled = true
		
		for view in self.view.subviews {
			view.isUserInteractionEnabled = true
		}
	}
	
	public func performAuth() {
		guard let loginVc = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(identifier: "LoginViewController") as? LoginViewController else {
			return
		}
		
		loginVc.delegate = self
		
		// Artifical delay purely for UX to add a little buffer between letting go of finger on slider, and login showing up
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			if self?.presentedViewController != nil {
				self?.presentedViewController?.present(loginVc, animated: true)
				
			} else {
				self?.present(loginVc, animated: true)
			}
		}
	}
	
	public func authSuccessful() {
		fatalError("SendAbstractConfirmViewController.authSuccessful must be overidden")
	}
	
	public func authFailure() {
		fatalError("SendAbstractConfirmViewController.authFailure must be overidden")
	}
	
	public static func checkForExpectedLedgerErrors(_ kukaiError: KukaiError) -> String? {
		if kukaiError.errorType == .internalApplication, let sub = kukaiError.subType {
			if case KukaiCoreSwift.LedgerService.TezosAppErrorCodes.EXC_REJECT = sub {
				return nil // Don't display error message for user choosing to reject the operation
				
			} else if case KukaiCoreSwift.LedgerService.GeneralErrorCodes.DEVICE_LOCKED = sub {
				return "Please unlock the Ledger device and try again"
				
			} else if case KukaiCoreSwift.LedgerService.GeneralErrorCodes.APP_CLOSED = sub {
				return "Please open the Tezos app on your ledger device and try again"
			}
		}
		
		return kukaiError.description
	}
}

extension SendAbstractConfirmViewController: LoginViewControllerDelegate {
	
	func authResults(success: Bool) {
		
		if success {
			authSuccessful()
			
		} else {
			authFailure()
		}
	}
}

extension SendAbstractConfirmViewController: UIAdaptivePresentationControllerDelegate {
	
	func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
		return swipeDownEnabled
	}
}
