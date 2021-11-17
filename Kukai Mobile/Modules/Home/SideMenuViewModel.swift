//
//  SideMenuViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit
import KukaiCoreSwift
import OSLog

enum SideMenutSection: CaseIterable {
	case wallets
}

class SideMenuViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = SideMenutSection
	typealias CellDataType = String
	
	var dataSource: UITableViewDiffableDataSource<SideMenutSection, String>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		let selectedAddress = DependencyManager.shared.selectedWallet?.address
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
			cell.textLabel?.text = item
			
			if item == selectedAddress {
				cell.accessoryType = .checkmark
			} else {
				cell.accessoryType = .none
			}
			
			return cell
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool) {
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		let wallets = WalletCacheService().fetchWallets()
		let addresses = wallets?.map({ $0.address }) ?? []
		
		var snapshot = NSDiffableDataSourceSnapshot<SideMenutSection, String>()
		snapshot.appendSections(SideMenutSection.allCases)
		snapshot.appendItems(addresses, toSection: .wallets)
		
		ds.apply(snapshot, animatingDifferences: animate)
			
		self.state = .success(nil)
	}
}
