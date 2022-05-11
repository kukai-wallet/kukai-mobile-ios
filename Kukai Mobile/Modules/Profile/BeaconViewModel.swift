//
//  BeaconViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class BeaconViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var peersSelected = true
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if self.peersSelected, let obj = item as? PeerDisplay, let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconConfigCell", for: indexPath) as? BeaconConfigCell {
				cell.nameLabel.text = obj.name
				cell.fieldNameLabel.text = "Server Relay:"
				cell.fieldValueLabel.text = obj.server
				return cell
				
			} else if !self.peersSelected, let obj = item as? PermissionDisplay, let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconConfigCell", for: indexPath) as? BeaconConfigCell {
				cell.nameLabel.text = obj.name
				cell.fieldNameLabel.text = "Address:"
				cell.fieldValueLabel.text = obj.address
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			self.state = .failure(ErrorResponse.unknownError(), "Unable to find datasource")
			return
		}
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		if peersSelected {
			BeaconService.shared.getPeers { result in
				guard let res = try? result.get() else {
					self.state = .failure(result.getFailure(), "Error fetching peers")
					return
				}
				
				snapshot.appendItems(res, toSection: 0)
			}
		} else {
			BeaconService.shared.getPermissions { result in
				guard let res = try? result.get() else {
					self.state = .failure(result.getFailure(), "Error fetching peers")
					return
				}
				
				snapshot.appendItems(res, toSection: 0)
			}
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		// Return success
		self.state = .success(nil)
	}
	
	func changePeersSelected(_ selected: Bool) {
		self.peersSelected = selected
		self.refresh(animate: true)
	}
}
