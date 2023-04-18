//
//  AccountsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift
import OSLog

protocol AccountsViewModelDelegate: UIViewController {
	func allWalletsRemoved()
}

struct AccountsHeaderObject: Hashable {
	let id = UUID()
	let header: String
	let menu: MenuViewController?
}

class AccountsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	public var selectedIndex: IndexPath = IndexPath(row: -1, section: -1)
	public weak var delegate: AccountsViewModelDelegate? = nil
	
	private var headers: [AccountsHeaderObject] = []
	
	
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
			
			if let obj = item as? AccountsHeaderObject, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsSectionHeaderCell", for: indexPath) as? AccountsSectionHeaderCell {
				cell.headingLabel.text = obj.header
				cell.setup(menuVC: obj.menu)
				
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
		
		guard DependencyManager.shared.walletList.count() > 0 else {
			delegate?.allWalletsRemoved()
			return
		}
		
	
		selectedIndex = IndexPath(row: -1, section: -1)
		
		let wallets = DependencyManager.shared.walletList
		let currentAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		var sections: [Int] = []
		var sectionData: [[AnyHashable]] = []
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([AccountsHeaderObject(header: "Social Wallets", menu: nil)])
		}
		for (index, metadata) in wallets.socialWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// HD's
		for (index, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			
			if let menu = menuFor(walletMetadata: metadata, hdWalletIndex: index) {
				sectionData.append([AccountsHeaderObject(header: "HD Wallet \(index + 1)", menu: menuFor(walletMetadata: metadata, hdWalletIndex: index))])
			}
			
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
			sectionData.append([AccountsHeaderObject(header: "Legacy Wallets", menu: nil)])
		}
		for (index, metadata) in wallets.linearWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Ledger
		if wallets.ledgerWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([AccountsHeaderObject(header: "Ledger Wallets", menu: nil)])
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
		
		
		// If user removed the currently selected wallet
		if selectedIndex.row == -1 {
			selectedIndex = IndexPath(row: 1, section: 0)
			DependencyManager.shared.selectedWalletMetadata = metadataFor(indexPath: selectedIndex)
		}
		
		self.state = .success(nil)
	}
	
	func metadataFor(indexPath: IndexPath) -> WalletMetadata? {
		return dataSource?.itemIdentifier(for: indexPath) as? WalletMetadata
	}
	
	/// Deleting a child index requires a HD parent wallet index (for performance reasons). Return the index of the HD wallet, if relevant
	func parentIndexForIndexPathIfRelevant(indexPath: IndexPath) -> Int? {
		
		if indexPath.row > 1, let parentItem = dataSource?.itemIdentifier(for: IndexPath(row: 1, section: indexPath.section)) as? WalletMetadata, parentItem.type == .hd {
			return DependencyManager.shared.walletList.hdWallets.firstIndex(where: { $0.address == parentItem.address })
		}
		
		return nil
	}
	
	private func menuFor(walletMetadata: WalletMetadata, hdWalletIndex: Int) -> MenuViewController? {
		guard let vc = delegate else { return nil }
		
		let addAccount = UIAction(title: "Add Account", image: UIImage(named: "AddNewAccount")) { [weak self] action in
			if let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) as? HDWallet,
			   let newChild = wallet.createChild(accountIndex: walletMetadata.children.count+1),
			   WalletCacheService().cache(wallet: newChild, childOfIndex: hdWalletIndex) {
				DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
				self?.refresh(animate: true)
				
			} else {
				vc.alert(errorWithMessage: "Unable to add child")
			}
		}
		
		return MenuViewController(actions: [[addAccount]], header: "HD Wallet \(hdWalletIndex+1)", sourceViewController: vc)
	}
}
