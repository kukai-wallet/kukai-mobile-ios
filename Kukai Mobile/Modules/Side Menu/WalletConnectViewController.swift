//
//  WalletConnectViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit
import Combine

class WalletConnectViewController: UIViewController, BottomSheetContainerDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = WalletConnectViewModel()
	private var bag = Set<AnyCancellable>()
	private var sessionToChangeAccount: Session? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.viewController = self
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView()
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}.store(in: &bag)
		
		WalletKit.instance.sessionsPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.sessionToChangeAccount = nil
				self?.viewModel.refresh(animate: true)
				self?.hideLoadingView()
			}.store(in: &bag)
		
		WalletConnectService.shared.$sessionsUpdated
			.dropFirst()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in
				self?.viewModel.refresh(animate: true)
				self?.hideLoadingView()
			}.store(in: &bag)
	}
	
	func bottomSheetDataChanged() {
		self.showLoadingView()
		
		// Change account for the given session
		if let session = self.sessionToChangeAccount {
			
			let newAddress = DependencyManager.shared.temporarySelectedWalletAddress ?? DependencyManager.shared.selectedWalletAddress ?? ""
			guard let newNamespaces = WalletConnectService.updateNamespaces(forSession: session, toAddress: newAddress) else {
				return
			}
			
			Task {
				do {
					
					
					try await WalletKit.instance.update(topic: session.topic, namespaces: newNamespaces)
					DispatchQueue.main.async { [weak self] in
						self?.viewModel.refresh(animate: true)
						UIViewController.removeLoadingView()
					}
					
				} catch {
					DispatchQueue.main.async { [weak self] in
						self?.sessionToChangeAccount = nil
						UIViewController.removeLoadingView()
						self?.windowError(withTitle: "error".localized(), description: error.localizedDescription)
					}
				}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "accounts", let wcSelectedAddress = sender as? String, let vc = segue.destination as? AccountsContainerViewController {
			vc.addressToMarkAsSelected = wcSelectedAddress
		}
	}
	
	@IBAction func reconnectTapped(_ sender: Any) {
		
		/*
		self.showLoadingModal { [weak self] in
			
			WalletConnectService.shared.reconnect { error in
				
				self?.hideLoadingView(completion: {
					if let err = error {
						self?.windowError(withTitle: "error".localized(), description: String.localized(String.localized("error-wc2-reconnect"), withArguments: err.localizedDescription) )
					}
				})
			}
		}
		*/
	}
}

extension WalletConnectViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
	}
	
	func menu(forSession: SessionObj?) -> UIMenu? {
		guard let forSession else { return nil }
		
		let disconnect = UIAction(title: "Disconnect", image: UIImage(named: "Remove"), attributes: .destructive) { action in
			Task {
				do {
					try await WalletKit.instance.disconnect(topic: forSession.topic)
				} catch {
					DispatchQueue.main.async { [weak self] in
						self?.windowError(withTitle: "error".localized(), description: error.localizedDescription)
					}
				}
				
				DispatchQueue.main.async { [weak self] in
					self?.viewModel.refresh(animate: true)
				}
			}
		}
		
		let wallet = UIAction(title: "Switch Wallet", image: UIImage(named: "WalletSwitch")?.resizedImage(size: CGSize(width: 26, height: 26))?.withTintColor(.colorNamed("BGB4"))) { [weak self] action in
			guard let firstSession = WalletKit.instance.getSessions().filter({ $0.topic == forSession.topic }).first,
				  let firstAccount = firstSession.accounts.first else {
				self?.windowError(withTitle: "error".localized(), description: "error-wc2-switch-no-pairing".localized())
				return
			}
			
			self?.sessionToChangeAccount = firstSession
			self?.performSegue(withIdentifier: "accounts", sender: firstAccount.address)
		}
		
		/*
		let newNetwork = (forPair.network == "Mainnet" ? "Ghostnet" : "Mainnet")
		let network = UIAction(title: "Switch to \(newNetwork)", image: UIImage(named: "Network")) { action in
			
		}
		*/
		
		return UIMenu(title: forSession.site, children: [disconnect, wallet/*, network*/ ])
	}
}
