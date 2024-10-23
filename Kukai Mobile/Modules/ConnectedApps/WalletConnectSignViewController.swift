//
//  WalletConnectSignViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import KukaiCoreSwift
import KukaiCryptoSwift
import WalletConnectNetworking
import Combine
import OSLog

class WalletConnectSignViewController: UIViewController, BottomSheetCustomFixedProtocol, SlideButtonDelegate {
	
	@IBOutlet weak var closeButton: CustomisableButton!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var payloadTextView: UITextView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet var slideButton: SlideButton!
	
	private var stringToSign: String = ""
	private var accountToSign: String = ""
	private var bag = Set<AnyCancellable>()
	private var didSend = false
	private var swipeDownEnabled = true
	
	var bottomSheetMaxHeight: CGFloat = 500
	var dimBackground: Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic, let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
				MediaProxyService.load(url: smallIconURL, to: self.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
			} else {
				self.iconView.image = UIImage.unknownToken()
			}
			self.nameLabel.text = session.peer.name
		}
		
		
		guard let request = TransactionService.shared.walletConnectOperationData.request, let params = try? request.params.get([String: String].self), let expression = params["payload"], let account = params["account"] else {
			return
		}
		
		stringToSign = expression
		accountToSign = account
		payloadTextView.text = expression.humanReadableStringFromMichelson()
		payloadTextView.contentInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 12)
		
		slideButton.delegate = self
		presentationController?.delegate = self
		
		
		/*
		 // Listen for partial success messages from ledger devices (if applicable)
		 LedgerService.shared
		 .$partialSuccessMessageReceived
		 .dropFirst()
		 .sink { [weak self] _ in
		 self?.alert(withTitle: "Approve on Ledger", andMessage: "Please dismiss this alert, and then approve sign on ledger")
		 }
		 .store(in: &bag)
		 */
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			self?.ledgerCheck()
		}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
			DispatchQueue.main.async { [weak self] in
				
				if status == .disconnected {
					self?.showLoadingModal()
					self?.updateLoadingModalStatusLabel(message: "Reconnecting ... ")
				} else {
					self?.hideLoadingModal()
				}
			}
		}.store(in: &bag)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		ledgerCheck()
	}
	
	private func ledgerCheck() {
		if let meta = DependencyManager.shared.walletList.metadata(forAddress: accountToSign), meta.type == .ledger {
			AccountsViewModel.askToConnectToLedgerIfNeeded(walletMetadata: meta) { success in
				if !success {
					self.dismiss(animated: true)
				}
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend {
			handleRejection(andDismiss: false)
		}
		
		if LedgerService.shared.getConnectedDeviceUUID() != nil {
			LedgerService.shared.disconnectFromDevice()
		}
	}
	
	public func blockInteraction() {
		self.swipeDownEnabled = false
		
		for view in self.view.subviews {
			if view != closeButton {
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
	
	@IBAction func copyButtonTapped(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = payloadTextView.text
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.showLoadingView()
		self.handleRejection()
	}
	
	private func handleRejection(andDismiss: Bool = true) {
		WalletConnectService.rejectCurrentRequest(completion: { [weak self] success, error in
			DispatchQueue.main.async { [weak self] in
				self?.hideLoadingView()
				
				if success {
					self?.didSend = true
					if andDismiss { self?.presentingViewController?.dismiss(animated: true) }
					
				} else {
					var message = ""
					if let err = error {
						message = err.localizedDescription
					} else {
						message = "error-wc2-unrecoverable".localized()
					}
					
					Logger.app.error("WC Rejction error: \(error)")
					self?.windowError(withTitle: "error".localized(), description: message)
					if andDismiss { self?.presentingViewController?.dismiss(animated: true) }
				}
			}
		})
	}
	
	func didCompleteSlide() {
		self.blockInteraction()
		self.performAuth()
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
		guard let wallet = WalletCacheService().fetchWallet(forAddress: accountToSign) else {
			self.unblockInteraction()
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			self.slideButton.resetSlider()
			return
		}
		
		// Sign and continue
		var str = self.stringToSign
		if str.prefix(2) == "0x" {
			let strIndex = str.index(str.startIndex, offsetBy: 2)
			str = String(str[strIndex...])
		}
		
		wallet.sign(str, isOperation: false) { [weak self] result in
			switch result {
				case .success(let signature):
					self?.didSend = true
					let updatedSignature = Base58Check.encode(message: signature, ellipticalCurve: wallet.privateKeyCurve())
					self?.handleApproval(signature: updatedSignature)
					
				case .failure(_):
					self?.unblockInteraction()
					self?.windowError(withTitle: "error".localized(), description: String.localized(String.localized("error-cant-sign"), withArguments: result.getFailure().description))
					self?.slideButton?.resetSlider()
			}
		}
	}
	
	public func authFailure() {
		self.unblockInteraction()
		self.slideButton.resetSlider()
	}
	
	private func handleApproval(signature: String) {
		WalletConnectService.approveCurrentRequest(signature: signature, opHash: nil, completion: { [weak self] success, error in
			DispatchQueue.main.async { [weak self] in
				self?.unblockInteraction()
				
				if success {
					self?.slideButton.markComplete(withText: "Complete")
					self?.didSend = true
					self?.presentingViewController?.dismiss(animated: true)
					
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
				}
			}
		})
	}
}

extension WalletConnectSignViewController: LoginViewControllerDelegate {
	
	func authResults(success: Bool) {
		
		if success {
			authSuccessful()
			
		} else {
			authFailure()
		}
	}
}

extension WalletConnectSignViewController: UIAdaptivePresentationControllerDelegate {
	
	func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
		return swipeDownEnabled
	}
}
