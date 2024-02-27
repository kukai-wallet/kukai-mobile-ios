//
//  SendAbstractConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/01/2024.
//

import UIKit
import KukaiCoreSwift
import OSLog

class SendAbstractConfirmViewController: UIViewController {
	
	public var isWalletConnectOp = false
	public var didSend = false
	
	public var connectedAppURL: URL? = nil
	public var currentSendData: TransactionService.SendData = TransactionService.SendData()
	public var currentBatchData: TransactionService.BatchData = TransactionService.BatchData()
	public var selectedMetadata: WalletMetadata? = nil
	
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend && isWalletConnectOp {
			handleRejection(andDismiss: false)
		}
	}
	
	func dismissAndReturn(collapseOnly: Bool) {
		self.dismiss(animated: true)
		
		if collapseOnly == false {
			(self.presentingViewController as? UINavigationController)?.popToHome()
		}
	}
	
	
	
	// MARK: - WC2 functions
	
	func handleRejection(andDismiss: Bool = true, collapseOnly: Bool = false) {
		if !isWalletConnectOp {
			if andDismiss { self.dismissAndReturn(collapseOnly: collapseOnly) }
			return
		}
		
		self.showLoadingView()
		WalletConnectService.rejectCurrentRequest(completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
				self?.hideLoadingView()
				
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
			})
		})
	}
	
	func handleApproval(opHash: String) {
		if !isWalletConnectOp {
			self.dismissAndReturn(collapseOnly: false)
			return
		}
		
		WalletConnectService.approveCurrentRequest(signature: nil, opHash: opHash, completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
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
		})
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
