//
//  AccountsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift
import OSLog

class AccountsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	public var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	
	class EditableDiffableDataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType> {
		override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
			if indexPath.row == 0 {
				return false
			}
			
			return true
		}
		
		override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
			return false
		}
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = EditableDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsSectionHeaderCell", for: indexPath) as? AccountsSectionHeaderCell {
				cell.headingLabel.text = obj
				return cell
				
			} else if let obj = item as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountItemCell", for: indexPath) as? AccountItemCell {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: obj, ofSize: .size_22)
				cell.iconView.image = walletMedia.image
				cell.titleLabel.text = walletMedia.title
				cell.subtitleLabel.text = walletMedia.subtitle
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		let wallets = DependencyManager.shared.walletList
		let currentAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		var sections: [Int] = []
		var sectionData: [[AnyHashable]] = []
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Social Wallets"])
		}
		for (index, metadata) in wallets.socialWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// HD's
		for (index, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			sectionData.append(["HD Wallet \(index + 1)"])
			
			sectionData[sections.count-1].append(metadata)
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				sectionData[sections.count-1].append(childMetadata)
				
				if childMetadata.address == currentAddress { selectedIndex = IndexPath(row: childIndex+1, section: sections.count-1) }
			}
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: 1, section: sections.count-1) }
		}
		
		
		// Linear
		if wallets.linearWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Legacy Wallets"])
		}
		for (index, metadata) in wallets.linearWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Ledger
		if wallets.ledgerWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Ledger Wallets"])
		}
		for (index, metadata) in wallets.ledgerWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func metadataFor(indexPath: IndexPath) -> WalletMetadata? {
		return dataSource?.itemIdentifier(for: indexPath) as? WalletMetadata
	}
}
