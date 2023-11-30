//
//  AccountsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
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
	public var isPresentingForConnectedApps = false
	public var addressToMarkAsSelected: String? = nil
	private var newWalletAutoSelected = false
	
	class EditableDiffableDataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType> {
		override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
		let currentAddress = addressToMarkAsSelected != nil ? addressToMarkAsSelected ?? "" : DependencyManager.shared.selectedWalletAddress ?? ""
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
				sectionData.append([AccountsHeaderObject(header: metadata.hdWalletGroupName ?? "", menu: menu)])
			}
			
			sectionData[sections.count-1].append(metadata)
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				sectionData[sections.count-1].append(childMetadata)
				
				if childMetadata.address == currentAddress { selectedIndex = IndexPath(row: childIndex+2, section: sections.count-1) }
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
		
		
		// Watch
		if !isPresentingForConnectedApps {
			if wallets.watchWallets.count > 0 {
				sections.append(sections.count)
				sectionData.append([AccountsHeaderObject(header: "Watch Wallets", menu: nil)])
			}
			for (index, metadata) in wallets.watchWallets.enumerated() {
				sectionData[sections.count-1].append(metadata)
				
				if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
			}
		}
		
		
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		
		// If user removed the currently selected wallet
		if selectedIndex.row == -1 {
			selectedIndex = IndexPath(row: 1, section: 0)
			newWalletAutoSelected = true
		}
		
		// Need to use reload for this viewModel as multiple buttons effect the state of options in the list
		ds.applySnapshotUsingReloadData(snapshot)
		
		// If we had to forcably set a wallet (due to edits / deletions), select the wallet
		if newWalletAutoSelected {
			DependencyManager.shared.selectedWalletMetadata = metadataFor(indexPath: selectedIndex)
			newWalletAutoSelected = false
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
		
		let edit = UIAction(title: "Edit Name", image: UIImage(named: "Edit")) { [weak self] action in
			
			// Fetch from store, otherwise it will be stale data
			if let meta = DependencyManager.shared.walletList.metadata(forAddress: walletMetadata.address) {
				self?.delegate?.performSegue(withIdentifier: "rename", sender: meta)
			}
		}
		
		let addAccount = UIAction(title: "Add Account", image: UIImage(named: "AddNewAccount")) { [weak self] action in
			
			vc.showLoadingView()
			self?.isPreviousAccountUsed(forAddress: walletMetadata.address, completion: { isUsed in
				guard isUsed else {
					vc.hideLoadingView()
					vc.windowError(withTitle: "error-previous-account-title".localized(), description: "error-previous-account-empty".localized())
					return
				}
				
				guard let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) as? HDWallet,
					  let newChild = wallet.createChild(accountIndex: walletMetadata.children.count+1) else {
					vc.hideLoadingView()
					vc.windowError(withTitle: "error".localized(), description: "error-cant-add-account".localized())
					return
				}
				
				WalletManagementService.cacheNew(wallet: newChild, forChildOfIndex: hdWalletIndex, markSelected: false) { [weak self] success in
					guard success else {
						vc.hideLoadingView()
						vc.windowError(withTitle: "error".localized(), description: "error-cant-cache".localized())
						return
					}
					
					self?.refresh(animate: true)
					vc.hideLoadingView()
				}
			})
		}
		
		let remove = UIAction(title: "Remove Wallet", image: UIImage(named: "Delete")) { [weak self] action in
			
			// Fetch from store, otherwise it will be stale data
			if let meta = DependencyManager.shared.walletList.metadata(forAddress: walletMetadata.address) {
				self?.delegate?.performSegue(withIdentifier: "remove", sender: meta)
			}
		}
		
		return MenuViewController(actions: [[edit, addAccount, remove]], header: walletMetadata.hdWalletGroupName, alertStyleIndexes: [IndexPath(row: 2, section: 0)], sourceViewController: vc)
	}
	
	private func isPreviousAccountUsed(forAddress address: String, completion: @escaping ((Bool) -> Void)) {
		var metadataToCheck = DependencyManager.shared.walletList.metadata(forAddress: address)
		if (metadataToCheck?.children.count ?? 0) > 0, let last = metadataToCheck?.children.last {
			metadataToCheck = last
		}
		
		guard let meta = metadataToCheck else {
			completion(false)
			return
		}
		
		WalletManagementService.isUsedAccount(address: meta.address, completion: completion)
	}
	
	func pullToRefresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		let addresses = DependencyManager.shared.walletList.addresses()
		DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainsFor(addresses: addresses) { [weak self] result in
			switch result {
				case .success(let response):
					
					for address in response.keys {
						let _ = DependencyManager.shared.walletList.set(mainnetDomain: response[address]?.mainnet, ghostnetDomain: response[address]?.ghostnet, forAddress: address)
					}
					
					let _ = WalletCacheService().encryptAndWriteMetadataToDisk(DependencyManager.shared.walletList)
					if let currentAddress = DependencyManager.shared.selectedWalletAddress {
						DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: currentAddress)
					}
					
					self?.refresh(animate: true)
					self?.state = .success(nil)
					
				case .failure(let error):
					self?.state = .failure(error, "Error occurred detching tezos domains")
			}
		}
	}
}
