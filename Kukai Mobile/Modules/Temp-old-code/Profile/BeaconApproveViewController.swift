//
//  BeaconApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/05/2022.
//

import UIKit
import BeaconCore
import BeaconBlockchainTezos

class BeaconApproveViewController: UIViewController {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var networkLabel: UILabel!
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		/*
		if let request = TransactionService.shared.beaconApproveData.request {
			nameLabel.text = request.appMetadata.name
			networkLabel.text = request.network.type.rawValue
		}
		*/
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		/*guard let wallet = DependencyManager.shared.selectedWallet, let request = TransactionService.shared.beaconApproveData.request else {
			self.alert(errorWithMessage: "Can't find wallet")
			return
		}
		
		BeaconService.shared.acceptPermissionRequest(permission: request, wallet: wallet) { [weak self] result in
			switch result {
				case .success(()):
					((self?.presentingViewController as? UINavigationController)?.viewControllers.last as? BeaconViewController)?.peerAdded()
					self?.presentingViewController?.dismiss(animated: true)
					
				case .failure(let error):
					self?.alert(errorWithMessage: "Error: \(error)")
			}
		}*/
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		/*guard let request = TransactionService.shared.beaconApproveData.request else {
			self.alert(errorWithMessage: "Can't find beacon object details")
			return
		}
		
		self.showLoadingModal()
		BeaconService.shared.rejectPermissionRequest(permission: request) { [weak self] result in
			switch result {
				case .success(()):
					self?.hideLoadingModal(completion: {
						self?.presentingViewController?.dismiss(animated: true)
					})
					
				case .failure(let error):
					self?.hideLoadingModal(completion: {
						self?.alert(errorWithMessage: "Error: \(error)")
					})
			}
		}*/
	}
}
