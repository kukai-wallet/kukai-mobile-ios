//
//  WalletConnectViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import Combine

class WalletConnectViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = WalletConnectViewModel()
	private var bag = Set<AnyCancellable>()
	private var pairingToChangeAccount: Pairing? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}.store(in: &bag)
		
		Sign.instance.sessionUpdatePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] (sessionTopic: String, namespaces: [String : SessionNamespace]) in
				self?.pairingToChangeAccount = nil
				self?.viewModel.refresh(animate: true)
				
				print("updating ....")
			}.store(in: &bag)
		
		WalletConnectService.shared.$didCleanAfterDelete
			.dropFirst()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in
				self?.viewModel.refresh(animate: true)
				
				print("deleting ....")
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
		
		
		// Change account for the given pairing
		if let pairing = pairingToChangeAccount {
			
			let newAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			guard let existingSession = Sign.instance.getSessions().first(where: { $0.pairingTopic == pairing.topic }),
				  let newNamespaces = WalletConnectService.updateNamespaces(forPairing: pairing, toAddress: newAddress) else {
				return
			}
			
			Task {
				do {
					try await Sign.instance.update(topic: existingSession.topic, namespaces: newNamespaces)
					
				} catch {
					DispatchQueue.main.async { [weak self] in
						self?.pairingToChangeAccount = nil
						self?.alert(errorWithMessage: "\(error)")
					}
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "accounts", let wcSelectedAddress = sender as? String, let vc = segue.destination as? AccountsContainerViewController {
			vc.addressToMarkAsSelected = wcSelectedAddress
		}
	}
	
	@IBAction func reconnectTapped(_ sender: Any) {

		self.showLoadingModal { [weak self] in
			
			WalletConnectService.shared.reconnect { error in
				
				self?.hideLoadingModal(completion: {
					if let err = error {
						self?.alert(errorWithMessage: "Unable to reconnect: \(err)")
					}
				})
			}
		}
	}
}

extension WalletConnectViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let pair = viewModel.pairFor(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) as? ConnectedAppCell else {
			return
		}
		
		let menu = menu(forPair: pair)
		menu.display(attachedTo: cell.iconView)
	}
	
	func menu(forPair: PairObj) -> MenuViewController {
		
		let disconnect = UIAction(title: "Disconnect", image: UIImage(named: "Remove")) { action in
			Task {
				do {
					try await Pair.instance.disconnect(topic: forPair.topic)
					
					for session in Sign.instance.getSessions().filter({ $0.pairingTopic == forPair.topic }) {
						try await Sign.instance.disconnect(topic: session.topic)
					}
					
					DispatchQueue.main.async { [weak self] in
						self?.viewModel.refresh(animate: true)
					}
				} catch {
					DispatchQueue.main.async { [weak self] in
						self?.alert(errorWithMessage: "\(error)")
					}
				}
			}
		}
		
		let wallet = UIAction(title: "Switch Wallet", image: UIImage(named: "WalletSwitch")) { [weak self] action in
			guard let pairing = try? Pair.instance.getPairing(for: forPair.topic),
				  let firstSession = Sign.instance.getSessions().filter({ $0.pairingTopic == pairing.topic }).first,
				  let firstAccount = firstSession.accounts.first else {
				return
			}
			
			self?.pairingToChangeAccount = pairing
			self?.performSegue(withIdentifier: "accounts", sender: firstAccount.address)
		}
		
		/*
		let newNetwork = (forPair.network == "Mainnet" ? "Ghostnet" : "Mainnet")
		let network = UIAction(title: "Switch to \(newNetwork)", image: UIImage(named: "Network")) { action in
			
		}
		*/
		
		return MenuViewController(actions: [[disconnect, wallet/*, network*/]], header: forPair.site, alertStyleIndexes: [IndexPath(row: 0, section: 0)], sourceViewController: self)
	}
}
