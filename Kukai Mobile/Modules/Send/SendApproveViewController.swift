//
//  SendApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import Combine
import Sodium
import CryptoSwift
import KukaiCoreSwift

class SendApproveViewController: UIViewController {

	@IBOutlet weak var fromIcon: UIImageView!
	@IBOutlet weak var fromAliasLabel: UILabel!
	@IBOutlet weak var fromAddressLabel: UILabel!
	
	@IBOutlet weak var amountToSend: UILabel?
	@IBOutlet weak var fiatLabel: UILabel?
	
	@IBOutlet weak var nftIcon: UIImageView?
	@IBOutlet weak var nftName: UILabel?
	
	@IBOutlet weak var toIcon: UIImageView!
	@IBOutlet weak var toAliasLabel: UILabel!
	@IBOutlet weak var toAddressLabel: UILabel!
	
	@IBOutlet weak var slideView: UIView?
	@IBOutlet weak var slideImage: UIImageView?
	@IBOutlet weak var slideText: UILabel?
	
	@IBOutlet weak var autoBroadcastbutton: UIButton?
	
	private var bag = Set<AnyCancellable>()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		guard let wallet = DependencyManager.shared.selectedWallet, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		fromAliasLabel.text = ""
		fromAddressLabel.text = wallet.address
		
		if let token = TransactionService.shared.sendData.chosenToken {
			amountToSend?.text = amount.normalisedRepresentation + " \(token.symbol)"
			fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT, let iconView = nftIcon {
			MediaProxyService.load(url: nft.thumbnailURL, to: iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: iconView.frame.size)
			nftName?.text = nft.name
			
		} else {
			amountToSend?.text = "0"
			fiatLabel?.text = ""
		}
		
		toAliasLabel.text = TransactionService.shared.sendData.destinationAlias
		toAddressLabel.text = TransactionService.shared.sendData.destination
		
		autoBroadcastbutton?.isSelected = true
		
		setupSlideView()
    }
	
	func setupSlideView() {
		let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(touched(_:)))
		slideImage?.addGestureRecognizer(gestureRecognizer)
		slideImage?.isUserInteractionEnabled = true
	}
	
	@objc private func touched(_ gestureRecognizer: UIGestureRecognizer) {
		guard let slideView = slideView, let slideImage = slideImage else {
			return
		}
		
		let padding: CGFloat = 4
		let startingCenterX: CGFloat = (slideImage.frame.width / 2) + padding
		let locationInView = gestureRecognizer.location(in: slideView)
		
		if let touchedView = gestureRecognizer.view {
			
			if gestureRecognizer.state == .changed {
				if locationInView.x >= startingCenterX && locationInView.x <= slideView.frame.width - startingCenterX {
					touchedView.center.x = locationInView.x
				}
				
				let diff = 100.0 - touchedView.frame.origin.x
				slideText?.alpha = diff / 100
				
			} else if gestureRecognizer.state == .ended {
				if locationInView.x >= ((slideView.frame.width - startingCenterX) - padding) {
					slideImage.alpha = 0
					slideText?.text = "Sending.."
					slideText?.textColor = UIColor.black
					slideText?.alpha = 1
					sendOperations()
					
				} else {
					slideText?.alpha = 1
					touchedView.center.x = startingCenterX
				}
			}
			
			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
	
	func resetSlider() {
		slideText?.text = ">> Slide to Send >>"
		slideText?.textColor = UIColor.lightGray
		
		slideImage?.center.x = ((slideImage?.frame.width ?? 2) / 2) + 4
		slideImage?.alpha = 1
	}
	
	func sendOperations() {
		guard let ops = TransactionService.shared.sendData.operations, let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find ops")
			resetSlider()
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { [weak self] sendResult in
			self?.hideLoadingModal(completion: nil)
			
			switch sendResult {
				case .success(let opHash):
					print("Sent: \(opHash)")
					self?.dismiss(animated: true, completion: nil)
					(self?.presentingViewController as? UINavigationController)?.popToHome()
					
				case .failure(let sendError):
					self?.alert(errorWithMessage: sendError.description)
			}
		}
	}
	
	@IBAction func autoBroadcastTapped(_ sender: Any) {
		autoBroadcastbutton?.isSelected = !(autoBroadcastbutton?.isSelected ?? true)
	}
	
	@IBAction func signTapped(_ sender: Any) {
		guard let wallet = DependencyManager.shared.selectedWallet as? LedgerWallet, let ops = TransactionService.shared.sendData.operations else {
			self.alert(errorWithMessage: "Can't get data")
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.getOperationMetadata(forWallet: wallet) { [weak self] metadataResult in
			guard let metadata = try? metadataResult.get() else {
				self?.hideLoadingModal(completion: nil)
				self?.alert(errorWithMessage: "Couldn't fetch metadata \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			DependencyManager.shared.tezosNodeClient.operationService.ledgerOperationPrepWithLocalForge(metadata: metadata, operations: ops, wallet: wallet) { ledgerPrepResult in
				guard let ledgerPrep = try? ledgerPrepResult.get() else {
					self?.hideLoadingModal(completion: nil)
					self?.alert(errorWithMessage: "Couldn't get ledger prep data \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
					return
				}
				
				TransactionService.shared.sendData.ledgerPrep = ledgerPrep
				self?.handleLedgerSend(ledgerPrep: ledgerPrep, wallet: wallet)
			}
		}
	}
	
	func handleLedgerSend(ledgerPrep: OperationService.LedgerPayloadPrepResponse, wallet: LedgerWallet) {
		
		// Connect to the ledger wallet, and request a signature from the device using the ledger prep
		LedgerService.shared.connectTo(uuid: wallet.ledgerUUID)
			.flatMap { _ -> AnyPublisher<String, ErrorResponse> in
				if ledgerPrep.canLedgerParse {
					return LedgerService.shared.sign(hex: ledgerPrep.watermarkedOp, parse: true)
				}
				
				return LedgerService.shared.sign(hex: ledgerPrep.blake2bHash, parse: false)
			}
			.sink(onError: { [weak self] error in
				self?.alert(errorWithMessage: "Error from ledger: \( error )")
				
			}, onSuccess: { [weak self] signature in
				self?.handle(signature: signature)
			})
			.store(in: &bag)
		
		
		// Listen for partial success messages
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateLoadingModalStatusLabel(message: "Please approve the signing request on your ledger device")
			}
			.store(in: &bag)
	}
	
	func handle(signature: String) {
		self.updateLoadingModalStatusLabel(message: "Signature received, Injecting ...")
		guard let ledgerPrep = TransactionService.shared.sendData.ledgerPrep, let binarySignature = Sodium.shared.utils.hex2bin(signature) else {
			self.hideLoadingModal(completion: nil)
			self.alert(errorWithMessage: "Unable to inject, as can't find prep data")
			return
		}
		
		DependencyManager.shared.tezosNodeClient.operationService.preapplyAndInject(forgedOperation: ledgerPrep.forgedOp,
																					signature: binarySignature,
																					signatureCurve: .ed25519,
																					operationPayload: ledgerPrep.payload,
																					operationMetadata: ledgerPrep.metadata) { [weak self] injectionResult in
			
			guard let opHash = try? injectionResult.get() else {
				self?.hideLoadingModal(completion: nil)
				self?.alert(errorWithMessage: "Preapply / Injection error: \( (try? injectionResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			self?.hideLoadingModal(completion: nil)
			
			print("Sent: \(opHash)")
			self?.dismiss(animated: true, completion: nil)
			(self?.presentingViewController as? UINavigationController)?.popToHome()
		}
	}
}
