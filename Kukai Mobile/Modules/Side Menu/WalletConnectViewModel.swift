//
//  WalletConnectViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign

struct PairObj: Hashable {
	let name: String
	let url: String
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
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self, let obj = item as? PairObj,  let cell = tableView.dequeueReusableCell(withIdentifier: "WalletConnectCell", for: indexPath) as? WalletConnectCell else { return UITableViewCell() }
			
			cell.nameLbl.text = obj.name
			cell.serverLbl.text = obj.url
			cell.row = indexPath.row
			cell.delegate = self
			return cell
				
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			self.state = .failure(KukaiError.unknown(), "Unable to find datasource")
			return
		}
		
		// Get data
		pairs = Pair.instance.getPairings().map({ pair -> PairObj in
			
			if pair.peer == nil {
				return PairObj(name: "Pending", url: "Waiting for request from dApp", topic: pair.topic)
				
			} else {
				return PairObj(name: pair.peer?.name ?? " ", url: pair.peer?.url ?? " ", topic: pair.topic)
			}
		})
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		snapshot.appendItems(pairs, toSection: 0)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		// Return success
		self.state = .success(nil)
	}
	
	@MainActor
	public func deleteAll() {
		self.state = .loading
		
		for (index, _) in pairs.enumerated() {
			deleteTapped(forRow: index)
		}
		
		self.refresh(animate: true)
	}
}

extension WalletConnectViewModel: WalletConnectCellProtocol {
	
	@MainActor
	func deleteTapped(forRow: Int) {
		self.state = .loading
		
		let item = pairs[forRow]
		Task {
			do {
				try await Pair.instance.disconnect(topic: item.topic)
				
				for session in Sign.instance.getSessions().filter({ $0.pairingTopic == item.topic }) {
					try await Sign.instance.disconnect(topic: session.topic)
				}
				
				DispatchQueue.main.async { [weak self] in
					self?.refresh(animate: true)
				}
			} catch {
				DispatchQueue.main.async { [weak self] in
					self?.state = .failure(KukaiError.internalApplicationError(error: error), "\(error)")
				}
			}
		}
	}
}
