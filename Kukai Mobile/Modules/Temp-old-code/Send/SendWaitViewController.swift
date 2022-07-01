//
//  SendWaitViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import KukaiCoreSwift

class SendWaitViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let amount = TransactionService.shared.sendData.chosenAmount,
			  let token = TransactionService.shared.sendData.chosenToken,
			  let destination = TransactionService.shared.sendData.destination,
			  let wallet = DependencyManager.shared.selectedWallet
		else {
			self.alert(errorWithMessage: "Can't get data")
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		let operations = OperationFactory.sendOperation(amount, of: token, from: wallet.address, to: destination)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] estiamteResult in
			guard let estimatedOps = try? estiamteResult.get() else {
				self?.hideLoadingModal(completion: nil)
				self?.alert(errorWithMessage: "Couldn't estimate transaction: \( (try? estiamteResult.getError()) ?? KukaiError.unknown() )")
				return
			}
			
			DependencyManager.shared.tezosNodeClient.send(operations: estimatedOps, withWallet: wallet) { sendResult in
				guard let opHash = try? sendResult.get() else {
					self?.hideLoadingModal(completion: nil)
					self?.alert(errorWithMessage: "Couldn't send transaction: \( (try? estiamteResult.getError()) ?? KukaiError.unknown() )")
					return
				}
				
				self?.hideLoadingModal(completion: nil)
				self?.alert(withTitle: "Success", andMessage: "Operation injected, hash: \(opHash)")
			}
		}
	}
}
