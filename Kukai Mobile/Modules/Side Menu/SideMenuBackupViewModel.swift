//
//  SideMenuBackupViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/09/2023.
//

import UIKit
import KukaiCoreSwift

class SideMenuBackupViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionCell", for: indexPath) as? SideMenuOptionCell {
				cell.iconView.image = obj.icon
				cell.setup(title: obj.title, subtitle: obj.subtitle ?? "", subtitleIsWarning: obj.subtitleIsWarning)
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		var options: [AnyHashable] = []
		
		for obj in DependencyManager.shared.walletList.allMetadata(onlySeedBased: true) {
			let title = obj.hdWalletGroupName ?? obj.walletNickname ?? obj.address.truncateTezosAddress()
			let subtitle = obj.backedUp ? "Backed Up" : "Not Backed Up"
			options.append(SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: title, subtitle: subtitle, subtitleIsWarning: !obj.backedUp, id: obj.address))
		}
		
		snapshot.appendSections(Array(0..<options.count))
		
		for (index, obj) in options.enumerated() {
			snapshot.appendItems([obj], toSection: index)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func details(forIndexPath: IndexPath) -> (address: String, backedUp: Bool)? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData else {
			return nil
		}
		
		return (address: obj.id, backedUp: !obj.subtitleIsWarning)
	}
}
