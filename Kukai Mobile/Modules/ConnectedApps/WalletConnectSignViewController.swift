//
//  WalletConnectSignViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import WalletConnectUtils
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
	weak var presenter: HomeTabBarController? = nil
	
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
	
	@IBAction func copyButtonTapped(_ sender: Any) {
		UIPasteboard.general.string = payloadTextView.text
	}
	
	@MainActor
	private func respondOnSign(signature: String) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC Approve Session error: Unable to find request")
			self.hideLoadingModal(completion: { [weak self] in
				self?.windowError(withTitle: "error".localized(), description: "Unable to find request object")
			})
			return
		}
		
		Logger.app.info("WC Approve Request: \(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(["signature": signature])))
				self.slideButton.markComplete(withText: "Complete")
				self.presenter?.didApproveSigning = true
				
				self.hideLoadingModal(completion: { [weak self] in
					TransactionService.shared.resetWalletConnectState()
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				Logger.app.error("WC Approve Session error: \(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.windowError(withTitle: "error".localized(), description: error.localizedDescription)
				})
			}
		}
	}
	
	@MainActor
	private func respondOnReject() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC Reject Session error: Unable to find request")
			self.hideLoadingModal(completion: { [weak self] in
				self?.windowError(withTitle: "error".localized(), description: "Unable to find request object")
			})
			return
		}
		
		Logger.app.info("WC Reject Request: \(request.id)")
		Task {
			do {
				try WalletConnectService.reject(topic: request.topic, requestId: request.id)
				self.hideLoadingModal(completion: { [weak self] in
					TransactionService.shared.resetWalletConnectState()
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				Logger.app.error("WC Reject Session error: \(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.windowError(withTitle: "error".localized(), description: error.localizedDescription)
				})
			}
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		respondOnReject()
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
				self?.respondOnSign(signature: updatedSignature)
			}
		}
	}
}
