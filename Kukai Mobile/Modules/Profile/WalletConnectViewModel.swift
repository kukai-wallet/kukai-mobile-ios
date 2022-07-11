//
//  WalletConnectViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign

struct SessionObj: Hashable {
	let name: String
	let url: String
	let topic: String
}

class WalletConnectViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var peersSelected = true
	
	private var sessions: [SessionObj] = []
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self, let obj = item as? SessionObj,  let cell = tableView.dequeueReusableCell(withIdentifier: "WalletConnectCell", for: indexPath) as? WalletConnectCell else { return UITableViewCell() }
			
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
		self.sessions = Sign.instance.getSessions().map { session -> SessionObj in
			return SessionObj(name: session.peer.name, url: session.peer.url, topic: session.topic)
		}
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		snapshot.appendItems(sessions, toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		// Return success
		self.state = .success(nil)
	}
}

extension WalletConnectViewModel: WalletConnectCellProtocol {
	
	@MainActor
	func deleteTapped(forRow: Int) {
		self.state = .loading
		
		let item = sessions[forRow]
		Task {
			do {
				try await Sign.instance.disconnect(topic: item.topic, reason: Reason(code: 0, message: "disconnect"))
				DispatchQueue.main.async { [weak self] in
					self?.refresh(animate: true)
				}
			} catch {
				DispatchQueue.main.async { [weak self] in
					self?.state = .failure(KukaiError.internalApplicationError(error: error), "Error occurred deleting session")
				}
			}
		}
	}
}
