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
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuHeadingCell", for: indexPath) as? SideMenuHeadingCell {
				cell.titleLabel.text = obj
				return cell
				
			} else if let obj = item.base as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionCell", for: indexPath) as? SideMenuOptionCell {
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
		let wallets = DependencyManager.shared.walletList
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		var sections: [Int] = []
		var sectionData: [[AnyHashableSendable]] = []
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([.init("Social Wallets")])
		}
		for metadata in wallets.socialWallets {
			let subtitle = metadata.backedUp ? "Backed Up" : "Not Backed Up"
			let media = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_20)
			sectionData[sections.count-1].append(.init(SideMenuOptionData(icon: media.image, title: media.title, subtitle: subtitle, subtitleIsWarning: !metadata.backedUp, id: metadata.address)))
		}
		
		
		// HD's
		if wallets.hdWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([.init("HD Wallets")])
		}
		for metadata in wallets.hdWallets {
			let title = metadata.walletNickname ?? metadata.address.truncateTezosAddress()
			let subtitle = metadata.backedUp ? "Backed Up" : "Not Backed Up"
			sectionData[sections.count-1].append(.init(SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: title, subtitle: subtitle, subtitleIsWarning: !metadata.backedUp, id: metadata.address)))
		}
		
		
		// Linear's
		if wallets.linearWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([.init("Legacy Wallets")])
		}
		for metadata in wallets.linearWallets {
			let title = metadata.walletNickname ?? metadata.address.truncateTezosAddress()
			let subtitle = metadata.backedUp ? "Backed Up" : "Not Backed Up"
			sectionData[sections.count-1].append(.init(SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: title, subtitle: subtitle, subtitleIsWarning: !metadata.backedUp, id: metadata.address)))
		}
		
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		/*
		for obj in DependencyManager.shared.walletList.allMetadata(onlySeedBased: true) {
			let title = obj.walletNickname ?? obj.address.truncateTezosAddress()
			let subtitle = obj.backedUp ? "Backed Up" : "Not Backed Up"
			options.append(SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: title, subtitle: subtitle, subtitleIsWarning: !obj.backedUp, id: obj.address))
		}
		
		snapshot.appendSections(Array(0..<options.count))
		
		for (index, obj) in options.enumerated() {
			snapshot.appendItems([obj], toSection: index)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		 */
		
		self.state = .success(nil)
	}
	
	func details(forIndexPath: IndexPath) -> (address: String, backedUp: Bool)? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath)?.base as? SideMenuOptionData else {
			return nil
		}
		
		return (address: obj.id, backedUp: !obj.subtitleIsWarning)
	}
}
