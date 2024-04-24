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
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
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
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend && isWalletConnectOp {
			handleRejection(andDismiss: false)
		}
	}
	
	func dismissAndReturn(collapseOnly: Bool) {
		DispatchQueue.main.async { [weak self] in
			self?.dismiss(animated: true, completion: {
				UIViewController.removeLoadingView()
				UIViewController.removeLoadingModal()
			})
			
			if collapseOnly == false {
				(self?.presentingViewController as? UINavigationController)?.popToHome()
			}
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
	
	func handleApproval(opHash: String) {
		AccountViewModel.reconnectAccountActivityListenerIfNeeded()
		
		if !isWalletConnectOp {
			self.dismissAndReturn(collapseOnly: false)
			return
		}
		
		WalletConnectService.approveCurrentRequest(signature: nil, opHash: opHash, completion: { [weak self] success, error in
			if success {
				self?.dismissAndReturn(collapseOnly: false)
				
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
	
	public func blockInteraction() {
		self.view.isUserInteractionEnabled = false
		self.swipeDownEnabled = false
	}
	
	public func unblockInteraction() {
		self.view.isUserInteractionEnabled = true
		self.swipeDownEnabled = true
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
