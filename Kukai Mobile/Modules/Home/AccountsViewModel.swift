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
	let showLess: Bool
}

struct AccountsMoreObject: Hashable {
	let id = UUID()
	let count: Int
	let isExpanded: Bool
	let hdWalletIndex: Int
}

class AccountsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	public var selectedIndex: IndexPath = IndexPath(row: -1, section: -1)
	public weak var delegate: AccountsViewModelDelegate? = nil
	public var isPresentingForConnectedApps = false
	public var addressToMarkAsSelected: String? = nil
	public var newAddressIndexPath: IndexPath? = nil
	
	private var bag = [AnyCancellable]()
	private var newWalletAutoSelected = false
	private var previousAddresses: [String] = []
	private var newlyAddedAddress: String? = nil
	private var shouldScrollToSelected = true
	private var expandedSection: Int? = nil
	private var reloadFromExpanding = false
	
	class EditableDiffableDataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType> {
		override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
			return true
		}
		
		override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
			return false
		}
	}
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$walletDeleted
			.dropFirst()
			.sink { [weak self] _ in
				self?.previousAddresses = []
			}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = EditableDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let obj = item as? AccountsHeaderObject, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsSectionHeaderCell", for: indexPath) as? AccountsSectionHeaderCell {
				cell.headingLabel.text = obj.header
				cell.setup(menuVC: obj.menu)
				cell.checkImage.isHidden = !(self?.selectedIndex.section == indexPath.section && (self?.selectedIndex.row ?? 0) > 3)
				
				return cell
				
			} else if let obj = item as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountItemCell", for: indexPath) as? AccountItemCell {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: obj, ofSize: .size_22)
				cell.iconView.image = walletMedia.image
				cell.titleLabel.text = walletMedia.title
				cell.subtitleLabel.text = walletMedia.subtitle
				
				if let newAddress = self?.newlyAddedAddress, obj.address == newAddress {
					cell.newIndicatorView.isHidden = false
				} else {
					cell.newIndicatorView.isHidden = true
				}
				
				return cell
				
			} else if let obj = item as? AccountsMoreObject, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsMoreCell", for: indexPath) as? AccountsMoreCell {
				cell.setup(obj)
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
		
		
		// used later to detect newly added addresses
		if previousAddresses.count == 0 {
			previousAddresses = wallets.addresses()
		}
		
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([AccountsHeaderObject(header: "Social Wallets", menu: nil, showLess: false)])
		}
		for (index, metadata) in wallets.socialWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// HD's
		for (index, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			
			if let menu = menuFor(walletMetadata: metadata, hdWalletIndex: index) {
				sectionData.append([AccountsHeaderObject(header: metadata.hdWalletGroupName ?? "", menu: menu, showLess: false)])
			}
			
			let isSectionExpanded = (expandedSection == sections.count-1)
			sectionData[sections.count-1].append(metadata)
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				if isSectionExpanded || (!isSectionExpanded && childIndex < 2) {
					sectionData[sections.count-1].append(childMetadata)
				}
				
				// If it is selected, take note of its postion, whether its in order or reordered for the sake of the collapse view
				if childMetadata.address == currentAddress {
					selectedIndex = IndexPath(row: childIndex+2, section: sections.count-1)
				}
				
				
				// Check if we added a new child address, which doesn't get auto selected
				if !previousAddresses.contains(childMetadata.address) {
					newlyAddedAddress = childMetadata.address
					newAddressIndexPath = IndexPath(row: childIndex, section: sections.count-1)
					previousAddresses.append(childMetadata.address)
				}
			}
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: 1, section: sections.count-1) }
			
			
			// if there are more than 3 items total, display moreCell
			if metadata.children.count > 2 {
				let moreData = AccountsMoreObject(count: metadata.children.count-2, isExpanded: isSectionExpanded, hdWalletIndex: index)
				sectionData[sections.count-1].append(moreData)
			}
		}
		
		
		// Linear
		if wallets.linearWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([AccountsHeaderObject(header: "Legacy Wallets", menu: nil, showLess: false)])
		}
		for (index, metadata) in wallets.linearWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Ledger
		if wallets.ledgerWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([AccountsHeaderObject(header: "Ledger Wallets", menu: nil, showLess: false)])
		}
		for (index, metadata) in wallets.ledgerWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Watch
		if !isPresentingForConnectedApps {
			if wallets.watchWallets.count > 0 {
				sections.append(sections.count)
				sectionData.append([AccountsHeaderObject(header: "Watch Wallets", menu: nil, showLess: false)])
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
		
		
		if reloadFromExpanding {
			ds.apply(snapshot, animatingDifferences: true)
			reloadFromExpanding = false
		} else {
			// Need to use reload for this viewModel as multiple buttons effect the state of options in the list
			ds.applySnapshotUsingReloadData(snapshot)
		}
		
		// If we had to forcably set a wallet (due to edits / deletions), select the wallet
		if newWalletAutoSelected {
			DependencyManager.shared.selectedWalletMetadata = metadataFor(indexPath: selectedIndex)
			newWalletAutoSelected = false
		}
		
		// Check if we created a new wallet and mark it as such
		if let address = DependencyManager.shared.selectedWalletAddress, !previousAddresses.contains(address) {
			newlyAddedAddress = address
			previousAddresses.append(address)
		}
		
		self.state = .success(nil)
		
		// Make sure its reset after each call
		newAddressIndexPath = nil
	}
	
	// We only want to disable this during the adding of new accounts, via the context menu for HD wallets. Which should only be triggered once
	// Once thats been triggered, unless another is added, we should resume scrolling to selected
	func scrollToSelected() -> Bool {
		let temp = shouldScrollToSelected
		shouldScrollToSelected = true
		
		return temp
	}
	
	func metadataFor(indexPath: IndexPath) -> WalletMetadata? {
		return dataSource?.itemIdentifier(for: indexPath) as? WalletMetadata
	}
	
	func handleMoreCellIfNeeded(indexPath: IndexPath) -> Bool {
		guard let _ = dataSource?.itemIdentifier(for: indexPath) as? AccountsMoreObject else {
			return false
		}
		
		if expandedSection == indexPath.section {
			expandedSection = nil
			
		} else {
			expandedSection = indexPath.section
		}
		
		reloadFromExpanding = true
		shouldScrollToSelected = false
		refresh(animate: true)
		return true
	}
	
	/// Deleting a child index requires a HD parent wallet index (for performance reasons). Return the index of the HD wallet, if relevant
	func parentIndexForIndexPathIfRelevant(indexPath: IndexPath) -> Int? {
		
		if indexPath.row > 1, let parentItem = dataSource?.itemIdentifier(for: IndexPath(row: 1, section: indexPath.section)) as? WalletMetadata, parentItem.type == .hd {
			return DependencyManager.shared.walletList.hdWallets.firstIndex(where: { $0.address == parentItem.address })
		}
		
		return nil
	}
	
	func isLastSubAccount(indexPath: IndexPath) -> Bool {
		if indexPath.row > 1,
		   let parentItem = dataSource?.itemIdentifier(for: IndexPath(row: 1, section: indexPath.section)) as? WalletMetadata,
		   let selectedItem = dataSource?.itemIdentifier(for: indexPath) as? WalletMetadata,
		   parentItem.type == .hd,
		   parentItem.children.last?.address == selectedItem.address {
			return true
		}
		
		return false
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
				
				WalletManagementService.cacheNew(wallet: newChild, forChildOfIndex: hdWalletIndex, backedUp: false, markSelected: false) { [weak self] errorString in
					if let eString = errorString {
						vc.hideLoadingView()
						vc.windowError(withTitle: "error".localized(), description: eString)
					} else {
						self?.shouldScrollToSelected = false
						self?.expandedSection = DependencyManager.shared.walletList.socialWallets.count > 0 ? hdWalletIndex+1 : hdWalletIndex
						self?.refresh(animate: true)
						vc.hideLoadingView()
					}
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
					self?.state = .failure(error, "Error occurred fetching tezos domains")
			}
		}
	}
}
