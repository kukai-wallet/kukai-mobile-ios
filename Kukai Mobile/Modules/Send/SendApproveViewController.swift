//
//  SendApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import CryptoSwift

class SendApproveViewController: UIViewController {

	@IBOutlet weak var fromIcon: UIImageView!
	@IBOutlet weak var fromAliasLabel: UILabel!
	@IBOutlet weak var fromAddressLabel: UILabel!
	
	@IBOutlet weak var amountToSend: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	
	@IBOutlet weak var toIcon: UIImageView!
	@IBOutlet weak var toAliasLabel: UILabel!
	@IBOutlet weak var toAddressLabel: UILabel!
	
	@IBOutlet weak var slideView: UIView?
	@IBOutlet weak var slideImage: UIImageView?
	@IBOutlet weak var slideText: UILabel?
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		guard let wallet = DependencyManager.shared.selectedWallet, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		fromAliasLabel.text = ""
		fromAddressLabel.text = wallet.address
		
		if let token = TransactionService.shared.sendData.chosenToken {
			amountToSend.text = amount.normalisedRepresentation + " \(token.symbol)"
			fiatLabel.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT {
			amountToSend.text = amount.normalisedRepresentation + " \(nft.symbol ?? "")"
			fiatLabel.text = ""
			
		} else {
			amountToSend.text = "0"
			fiatLabel.text = ""
		}
		
		toAliasLabel.text = TransactionService.shared.sendData.destinationAlias
		toAddressLabel.text = TransactionService.shared.sendData.destination
		
		
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
					(self?.presentingViewController as? UINavigationController)?.popToHome()
					self?.dismiss(animated: true, completion: nil)
					
				case .failure(let sendError):
					self?.alert(errorWithMessage: sendError.description)
			}
		}
	}
}
