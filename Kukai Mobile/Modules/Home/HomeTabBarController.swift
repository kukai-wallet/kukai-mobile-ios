//
//  HomeTabBarController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos

class HomeTabBarController: UITabBarController {
	
	@IBOutlet weak var accountButtonParent: UIBarButtonItem!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var sendButton: UIButton!
	
	private var walletChangeCancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateAccountButton()
			}
		
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: (self.view.frame.width * 0.75)))
		
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 34))
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 34))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetState()
		updateAccountButton()
		
		
		BeaconService.shared.operationDelegate = self
		BeaconService.shared.startBeacon(completion: ({ _ in}))
		
		// TODO: remove all permissions doesn't seem to do anything
		/*
		BeaconService.shared.startBeacon { started in
			print("Beacon successfully started: \(started)")
			
			BeaconService.shared.removeAllPeers { result in
				BeaconService.shared.removerAllPermissions { result2 in
					print("Beacon: everything gone")
				}
			}
		}
		*/
	}
	
	public func updateAccountButton() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			return
		}
		
		accountButton.setImage((wallet.type == .torus) ? UIImage(systemName: "xmark.octagon") : UIImage(), for: .normal)
		accountButton.setTitle("Wallet Type: \(wallet.type.rawValue)\n\(wallet.address)", for: .normal)
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
}

extension HomeTabBarController: BeaconServiceOperationDelegate {
	
	func operationRequest(requestingAppName: String, operationRequest: OperationTezosRequest) {
		self.alert(withTitle: "Approve Operation?", andMessage: "Operation requested by: \(requestingAppName)", okText: "Ok", okAction: { action in
			
			if let wallet = WalletCacheService().fetchPrimaryWallet() {
				let convertedOps = BeaconService.process(operation: operationRequest, forWallet: wallet)
				print("\n\n\n Converted OPs: \(convertedOps) \n\n\n")
				
				DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, withWallet: wallet) { result in
					guard let estiamtedOps = try? result.get() else {
						print("Error: \(result)")
						return
					}
					
					DependencyManager.shared.tezosNodeClient.send(operations: estiamtedOps, withWallet: wallet) { sendResult in
						guard let opHash = try? sendResult.get() else {
							print("Error: \(sendResult)")
							return
						}
						
						BeaconService.shared.approveOperationRequest(operation: operationRequest, opHash: opHash) { beaconResult in
							print("\n\n\n BeaconResult: \(beaconResult) \n\n\n")
						}
					}
				}
			}
			
		}, cancelText: "cancel") { action in
			
		}
	}
}
