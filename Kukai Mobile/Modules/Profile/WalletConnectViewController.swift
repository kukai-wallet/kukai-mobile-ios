//
//  WalletConnectViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import Combine
import OSLog

class WalletConnectViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var deleteAllButton: UIButton!
	
	private let viewModel = WalletConnectViewModel()
	private var cancellable: AnyCancellable?
	
	private let scanner = ScanViewController()
	private var bag = [AnyCancellable]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		scanner.withTextField = true
		
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
		
		setupWCCallbacks()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	public func sessionAdded() {
		self.viewModel.refresh(animate: true)
	}
	
	@IBAction func plusTapped(_ sender: Any) {
		scanner.delegate = self
		self.present(scanner, animated: true, completion: nil)
	}
	
	@IBAction func deleteAllTapped(_ sender: Any) {
		self.viewModel.deleteAll()
	}
	
	
	
	// MARK: - Wallet Connect
	/*
	@MainActor
	private func pairClient(uri: String) {
		os_log("WC pairing to %@", log: .default, type: .info, uri)
		Task {
			do {
				try await Sign.instance.pair(uri: uri)
			} catch {
				os_log("WC Pairing connect error: %@", log: .default, type: .error, "\(error)")
			}
		}
	}
	*/
	public func setupWCCallbacks() {
		/*Sign.instance.sessionProposalPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionProposal in
				os_log("WC sessionProposalPublisher %@", log: .default, type: .info)
				TransactionService.shared.walletConnectOperationData.proposal = sessionProposal
				self?.performSegue(withIdentifier: "approve", sender: nil)
			}.store(in: &bag)
		
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				os_log("WC sessionSettlePublisher %@", log: .default, type: .info)
				self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				os_log("WC sessionDeletePublisher %@", log: .default, type: .info)
				self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
		*/
	}
}

extension WalletConnectViewController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		if code == "" { return }
		
		//pairClient(uri: code)
	}
}
