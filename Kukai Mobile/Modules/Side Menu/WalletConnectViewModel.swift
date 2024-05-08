//
//  WalletConnectViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import WalletConnectSign

struct PairObj: Hashable {
	let icon: URL?
	let site: String
	let address: String?
	let network: String?
	let topic: String
}

class WalletConnectViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var peersSelected = true
	
	private var pairs: [PairObj] = []
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let _ = item as? UUID {
				return tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath)
				
			} else if let obj = item as? PairObj, let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectedApp", for: indexPath) as? ConnectedAppCell {
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
		let sortedPairs = Pair.instance.getPairings().sorted { lhs, rhs in
			return lhs.expiryDate < rhs.expiryDate
		}
		pairs = sortedPairs.compactMap({ pair -> PairObj? in
			
			let sessions = Sign.instance.getSessions().filter({ $0.pairingTopic == pair.topic })
			
			if pair.peer == nil || sessions.count == 0 {
				return nil
				
			} else {
				let firstSession = sessions.first
				let firstAccount = firstSession?.accounts.first
				let address = PublicKey.publicKeyHash(fromBase58EncodedKey: firstAccount?.address ?? "")
				let network = firstAccount?.blockchain.reference == "ghostnet" ? "Ghostnet" : "Mainnet"
				let iconURL = URL(string: pair.peer?.icons.first ?? "")
				
				return PairObj(icon: iconURL, site: pair.peer?.name ?? " ", address: address, network: network, topic: pair.topic)
			}
		})
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		if pairs.count > 0 {
			snapshot.appendItems(pairs, toSection: 0)
		} else {
			snapshot.appendItems([UUID()], toSection: 0)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		// Return success
		self.state = .success(nil)
	}
	
	func pairFor(indexPath: IndexPath) -> PairObj? {
		return dataSource?.itemIdentifier(for: indexPath) as? PairObj
	}
}
