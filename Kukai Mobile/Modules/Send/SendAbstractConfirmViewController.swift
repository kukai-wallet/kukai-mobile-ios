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
	
	func dismissAndReturn() {
		if !isWalletConnectOp {
			TransactionService.shared.resetAllState()
		}
		
		self.dismiss(animated: true)
		(self.presentingViewController as? UINavigationController)?.popToHome()
	}
	
	
	
	// MARK: - WC2 functions
	
	func handleRejection(andDismiss: Bool = true) {
		if !isWalletConnectOp {
			if andDismiss { self.dismissAndReturn() }
			return
		}
		
		WalletConnectService.rejectCurrentRequest(completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
				if success {
					if andDismiss { self?.dismissAndReturn() }
					
				} else {
					var message = ""
					if let err = error {
						message = err.localizedDescription
					} else {
						message = "error-wc2-unrecoverable".localized()
					}
					
					Logger.app.error("WC Rejction error: \(error)")
					self?.windowError(withTitle: "error".localized(), description: message)
					self?.dismissAndReturn()
				}
			})
		})
	}
	
	func handleApproval(opHash: String) {
		if !isWalletConnectOp {
			self.dismissAndReturn()
			return
		}
		
		WalletConnectService.approveCurrentRequest(signature: nil, opHash: opHash, completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
				if success {
					self?.dismissAndReturn()
					
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
					self?.dismissAndReturn()
				}
			})
		})
	}
}
