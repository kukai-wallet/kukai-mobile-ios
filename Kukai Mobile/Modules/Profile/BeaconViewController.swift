//
//  BeaconViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2022.
//

import UIKit
import Combine
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos

class BeaconViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var deleteAllButton: UIButton!
	
	private let viewModel = BeaconViewModel()
	private var cancellable: AnyCancellable?
	
	private let scanner = ScanViewController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
		BeaconService.shared.connectionDelegate = self
	}
	
	public func peerAdded() {
		self.viewModel.refresh(animate: true)
	}
	
	@IBAction func plusTapped(_ sender: Any) {
		scanner.delegate = self
		self.present(scanner, animated: true, completion: nil)
	}
	
	@IBAction func segmentedTapped(_ sender: Any) {
		self.viewModel.changePeersSelected((sender as? UISegmentedControl)?.selectedSegmentIndex == 0)
	}
	
	@IBAction func deleteAllTapped(_ sender: Any) {
	}
}

extension BeaconViewController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		let peer = BeaconService.shared.createPeerObjectFromQrCode(code)
		BeaconService.shared.addPeer(peer) { result in
			print("BeaconViewController Peer added: \(result)")
		}
	}
}

extension BeaconViewController: BeaconServiceConnectionDelegate {
	
	func permissionRequest(requestingAppName: String, permissionRequest: PermissionTezosRequest) {
		TransactionService.shared.currentTransactionType = .beaconApprove
		TransactionService.shared.beaconApproveData.request = permissionRequest
		
		self.performSegue(withIdentifier: "beaconApprove", sender: self)
	}
	
	func signPayload(requestingAppName: String, humanReadableString: String, payloadRequest: SignPayloadTezosRequest) {
		TransactionService.shared.currentTransactionType = .beaconSign
		TransactionService.shared.beaconSignData.request = payloadRequest
		TransactionService.shared.beaconSignData.humanReadableString = humanReadableString
		
		self.performSegue(withIdentifier: "beaconSign", sender: self)
	}
}
