//
//  BeaconOperationApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/05/2022.
//

import UIKit
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos

class BeaconOperationApproveViewController: UIViewController {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var networkLabel: UILabel!
	@IBOutlet weak var entrypoint: UILabel!
	@IBOutlet weak var networkCostLabel: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let data = TransactionService.shared.beaconOperationData
		
		nameLabel.text = data.beaconRequest?.appMetadata?.name ?? "..."
		networkLabel.text = data.beaconRequest?.network.identifier
		entrypoint.text = data.entrypointToCall ?? "..."
		networkCostLabel.text = (data.estimatedOperations ?? []).map({ $0.operationFees?.allFees() ?? .zero() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " tez"
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		guard let ops = TransactionService.shared.beaconOperationData.estimatedOperations,
			  let wallet = DependencyManager.shared.selectedWallet,
			  let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		self.showLoadingView()
		DependencyManager.shared.tezosNodeClient.send(operations: ops, withWallet: wallet) { [weak self] sendResult in
			switch sendResult {
				case .success(let opHash):
					
					// Let beacon know the request succeeded
					BeaconService.shared.approveOperationRequest(operation: beaconRequest, opHash: opHash) { beaconResult in
						self?.hideLoadingView()
						
						print("Sent: \(opHash)")
						self?.dismiss(animated: true, completion: nil)
						(self?.presentingViewController as? UINavigationController)?.popToHome()
					}
					
				case .failure(let sendError):
					self?.alert(errorWithMessage: sendError.description)
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		self.showLoadingView()
		
		let asRequestObject = Tezos.Request.Blockchain.operation(beaconRequest)
		BeaconService.shared.rejectRequest(request: asRequestObject) { [weak self] result in
			self?.hideLoadingView()
			
			switch result {
				case .success(()):
					self?.presentingViewController?.dismiss(animated: true)
					
				case .failure(let error):
					self?.alert(errorWithMessage: "\(error)")
			}
		}
	}
}
