//
//  WalletConnectViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit

struct SessionObj: Hashable {
	let icon: URL?
	let site: String
	let address: String?
	let network: String?
	let topic: String
}

class WalletConnectViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	var peersSelected = true
	
	private var sessions: [SessionObj] = []
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let _ = item.base as? UUID {
				return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
				
			} else if let obj = item.base as? SessionObj, let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectedApp", for: indexPath) as? ConnectedAppCell {
				let iconURL = MediaProxyService.url(fromUri: obj.icon, ofFormat: MediaProxyService.Format.icon.rawFormat())
				MediaProxyService.load(url: iconURL, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				cell.siteLabel.text = obj.site
				cell.networkLabel.text = obj.network
				
				if let add = obj.address, let metadata = DependencyManager.shared.walletList.metadata(forAddress: add) {
					let media = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_20)
					cell.addressIconView.image = media.image
					cell.titleLabel.text = media.title
					cell.subtitleLabel.text = media.subtitle
				} else {
					cell.addressIconView.image = TransactionService.tezosLogo(ofSize: .size_20)
					cell.titleLabel.text = obj.address
					cell.subtitleLabel.text = ""
				}
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			self.state = .failure(KukaiError.unknown(), "Unable to find datasource")
			return
		}
		
		// Get data
		let sortedSessions = WalletKit.instance.getSessions().sorted { lhs, rhs in
			return lhs.expiryDate < rhs.expiryDate
		}
		
		sessions = sortedSessions.compactMap({ session -> SessionObj? in
			let blockchainReferenceString = session.namespaces["tezos"]?.accounts.first?.reference
			let network = blockchainReferenceString == "ghostnet" ? "Ghostnet" : "Mainnet"
			let iconURL = URL(string: session.peer.icons.first ?? "")
			return SessionObj(icon: iconURL, site: session.peer.name, address: session.accounts.first?.address ?? "", network: network, topic: session.topic)
		})
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0])
		
		if sessions.count > 0 {
			snapshot.appendItems(sessions.map({.init($0)}), toSection: 0)
		} else {
			snapshot.appendItems([.init(UUID())], toSection: 0)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		// Return success
		self.state = .success(nil)
	}
	
	func sessionFor(indexPath: IndexPath) -> SessionObj? {
		return dataSource?.itemIdentifier(for: indexPath)?.base as? SessionObj
	}
}
