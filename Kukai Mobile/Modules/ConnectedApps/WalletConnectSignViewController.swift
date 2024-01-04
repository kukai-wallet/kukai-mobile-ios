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
import Combine
import OSLog

class WalletConnectSignViewController: UIViewController, BottomSheetCustomFixedProtocol, SlideButtonDelegate {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var payloadTextView: UITextView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet var slideButton: SlideButton!
	
	private var stringToSign: String = ""
	private var accountToSign: String = ""
	private var bag = Set<AnyCancellable>()
	
	var bottomSheetMaxHeight: CGFloat = 500
	var dimBackground: Bool = true
	private var didSend = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic, let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: .icon)
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
		payloadTextView.contentInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
		
		slideButton.delegate = self
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend {
			handleRejection(andDismiss: false)
		}
	}
	
	@IBAction func copyButtonTapped(_ sender: Any) {
		UIPasteboard.general.string = payloadTextView.text
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.showLoadingModal { [weak self] in
			self?.handleRejection()
		}
	}
	
	private func handleRejection(andDismiss: Bool = true) {
		WalletConnectService.rejectCurrentRequest(completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
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
				}
			})
		})
	}
	
	func didCompleteSlide() {
		guard let wallet = WalletCacheService().fetchWallet(forAddress: accountToSign) else {
			self.windowError(withTitle: "error".localized(), description: "Can't find requested wallet: \(accountToSign)")
			return
		}
		
		// Listen for partial success messages from ledger devices (if applicable)
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.alert(withTitle: "Approve on Ledger", andMessage: "Please dismiss this alert, and then approve sign on ledger")
			}
			.store(in: &bag)
		
		
		// Sign and continue
		self.showLoadingModal { [weak self] in
			var str = self?.stringToSign ?? ""
			if str.prefix(2) == "0x" {
				let strIndex = str.index(str.startIndex, offsetBy: 2)
				str = String(str[strIndex...])
			}
			
			wallet.sign(str, isOperation: false) { [weak self] result in
				guard let signature = try? result.get() else {
					self?.hideLoadingModal(completion: { [weak self] in
						self?.windowError(withTitle: "error".localized(), description: String.localized(String.localized("error-cant-sign"), withArguments: result.getFailure().description))
					})
					return
				}
				
				let updatedSignature = Base58Check.encode(message: signature, ellipticalCurve: wallet.privateKeyCurve())
				self?.handleApproval(signature: updatedSignature)
			}
		}
	}
	
	private func handleApproval(signature: String) {
		WalletConnectService.approveCurrentRequest(signature: signature, opHash: nil, completion: { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
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
			})
		})
	}
}
