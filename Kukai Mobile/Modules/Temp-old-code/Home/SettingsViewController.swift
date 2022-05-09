//
//  SettingsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift
//import BeaconSDK

class SettingsViewController: UIViewController {
	
	/*
	private let scanner = ScanViewController()
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		BeaconService.shared.startBeacon { started in
			print("Beacon successfully started: \(started)")
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	@IBAction func registerBeaconTapped(_ sender: Any) {
		scanner.delegate = self
		self.present(scanner, animated: true, completion: nil)
	}
	
	@IBAction func deleteWallet(_ sender: Any) {
		let _ = WalletCacheService().deleteCacheAndKeys()
		self.navigationController?.popToRootViewController(animated: true)
	}*/
}

/*
extension SettingsViewController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		let peer = BeaconService.shared.createPeerObjectFromQrCode(code)
		BeaconService.shared.connectionDelegate = self
		BeaconService.shared.operationDelegate = self
		BeaconService.shared.addPeer(peer) { result in
			print("Peer added: \(result)")
		}
	}
}

extension SettingsViewController: BeaconServiceConnectionDelegate {
	
	func permissionRequest(requestingAppName: String, permissionRequest: Beacon.Request.Permission) {
		self.alert(withTitle: "Approve Connection?", andMessage: "Do you want to approve the connection to: \(requestingAppName)", okText: "Ok", okAction: { action in
			
			if let wallet = WalletCacheService().fetchPrimaryWallet() {
				BeaconService.shared.acceptPermissionRequest(permission: permissionRequest, wallet: wallet) { result in
					print("\n\n\n Pairing result: \(result) \n\n\n")
				}
			}
			
		}, cancelText: "cancel") { action in
			
		}
	}
}

extension SettingsViewController: BeaconServiceOperationDelegate {
	
	func operationRequest(requestingAppName: String, operationRequest: Beacon.Request.Operation) {
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
*/
