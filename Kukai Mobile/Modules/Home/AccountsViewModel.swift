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
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	public var selectedIndex: IndexPath = IndexPath(row: -1, section: -1)
	public weak var delegate: AccountsViewModelDelegate? = nil
	public var isPresentingForConnectedApps = false
	public var addressToMarkAsSelected: String? = nil
	public var newAddressIndexPath: IndexPath? = nil
	
	private var bag = [AnyCancellable]()
	private static var staticBag = [AnyCancellable]()
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
		cleanup()
	}
	
	func cleanup() {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = EditableDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let obj = item.base as? AccountsHeaderObject, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsSectionHeaderCell", for: indexPath) as? AccountsSectionHeaderCell {
				cell.headingLabel.text = obj.header
				cell.setup(menuVC: obj.menu)
				cell.checkImage?.isHidden = !(self?.selectedIndex.section == indexPath.section && (self?.selectedIndex.row ?? 0) > 3)
				
				return cell
				
			} else if let obj = item.base as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountItemCell", for: indexPath) as? AccountItemCell {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: obj, ofSize: .size_22)
				cell.iconView.image = walletMedia.image
				cell.titleLabel.text = walletMedia.title
				cell.subtitleLabel.text = walletMedia.subtitle
				
				if let newAddress = self?.newlyAddedAddress, obj.address == newAddress {
					cell.newIndicatorView?.isHidden = false
				} else {
					cell.newIndicatorView?.isHidden = true
				}
				
				return cell
				
			} else if let obj = item.base as? AccountsMoreObject, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsMoreCell", for: indexPath) as? AccountsMoreCell {
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
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		
		var sections: [SectionEnum] = []
		var sectionData: [[AnyHashableSendable]] = []
		
		
		// used later to detect newly added addresses
		if previousAddresses.count == 0 {
			previousAddresses = wallets.addresses()
		}
		
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([.init(AccountsHeaderObject(header: "Social Wallets", menu: nil, showLess: false))])
		}
		for (index, metadata) in wallets.socialWallets.enumerated() {
			sectionData[sections.count-1].append(.init(metadata))
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// HD's
		handleGroupedData(metadataArray: wallets.hdWallets, sections: &sections, sectionData: &sectionData, currentAddress: currentAddress)
		
		
		// Linear
		if wallets.linearWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append([.init(AccountsHeaderObject(header: "Legacy Wallets", menu: nil, showLess: false))])
		}
		for (index, metadata) in wallets.linearWallets.enumerated() {
			sectionData[sections.count-1].append(.init(metadata))
			
			if metadata.address == currentAddress { selectedIndex = IndexPath(row: index+1, section: sections.count-1) }
		}
		
		
		// Ledger
		handleGroupedData(metadataArray: wallets.ledgerWallets, sections: &sections, sectionData: &sectionData, currentAddress: currentAddress)
		
		
		// Watch
		if !isPresentingForConnectedApps {
			if wallets.watchWallets.count > 0 {
				sections.append(sections.count)
				sectionData.append([.init(AccountsHeaderObject(header: "Watch Wallets", menu: nil, showLess: false))])
			}
			for (index, metadata) in wallets.watchWallets.enumerated() {
				sectionData[sections.count-1].append(.init(metadata))
				
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
	
	private func handleGroupedData(metadataArray: [WalletMetadata], sections: inout [Int], sectionData: inout [[AnyHashableSendable]], currentAddress: String) {
		
		for (index, metadata) in metadataArray.enumerated() {
			sections.append(sections.count)
			
			if let menu = menuFor(walletMetadata: metadata, hdWalletIndex: index) {
				sectionData.append([.init(AccountsHeaderObject(header: metadata.hdWalletGroupName ?? "", menu: menu, showLess: false))])
			}
			
			let isSectionExpanded = (expandedSection == sections.count-1)
			sectionData[sections.count-1].append(.init(metadata))
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				
				// If child should be visible
				if isSectionExpanded || (!isSectionExpanded && childIndex < 2) {
					sectionData[sections.count-1].append(.init(childMetadata))
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
				sectionData[sections.count-1].append(.init(moreData))
			}
		}
	}
	
	// We only want to disable this during the adding of new accounts, via the context menu for HD wallets. Which should only be triggered once
	// Once thats been triggered, unless another is added, we should resume scrolling to selected
	func scrollToSelected() -> Bool {
		let temp = shouldScrollToSelected
		shouldScrollToSelected = true
		
		return temp
	}
	
	func metadataFor(indexPath: IndexPath) -> WalletMetadata? {
		return dataSource?.itemIdentifier(for: indexPath)?.base as? WalletMetadata
	}
	
	func handleMoreCellIfNeeded(indexPath: IndexPath) -> Bool {
		guard let _ = dataSource?.itemIdentifier(for: indexPath)?.base as? AccountsMoreObject else {
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
		var firstMetadata: WalletMetadata? = nil
		for i in 1..<3 {
			if let obj = dataSource?.itemIdentifier(for: IndexPath(row: i, section: indexPath.section))?.base as? WalletMetadata {
				firstMetadata = obj
				break
			}
		}
		
		if indexPath.row > 1, let parentItem = firstMetadata {
			
			switch parentItem.type {
				case .regular, .regularShifted, .social:
					return nil
					
				case .hd:
					return DependencyManager.shared.walletList.hdWallets.firstIndex(where: { $0.address == parentItem.address })
					
				case .ledger:
					return DependencyManager.shared.walletList.ledgerWallets.firstIndex(where: { $0.address == parentItem.address })
			}
		}
		
		return nil
	}
	
	func isLastSubAccount(indexPath: IndexPath) -> Bool {
		var firstMetadata: WalletMetadata? = nil
		for i in 1..<3 {
			if let obj = dataSource?.itemIdentifier(for: IndexPath(row: i, section: indexPath.section))?.base as? WalletMetadata {
				firstMetadata = obj
				break
			}
		}
		
		if indexPath.row > 1,
		   let parentItem = firstMetadata,
		   let selectedItem = dataSource?.itemIdentifier(for: indexPath)?.base as? WalletMetadata,
		   (parentItem.type == .hd || parentItem.type == .ledger),
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
			AccountsViewModel.askToConnectToLedgerIfNeeded(walletMetadata: walletMetadata) { success in
				guard success else {
					vc.hideLoadingView()
					LedgerService.shared.disconnectFromDevice()
					return
				}
				
				AddAccountViewModel.addAccount(forMetadata: walletMetadata, hdWalletIndex: hdWalletIndex, forceMainnet: false) { [weak self] errorTitle, errorMessage in
					vc.hideLoadingView()
					LedgerService.shared.disconnectFromDevice()
					if let title = errorTitle, let message = errorMessage {
						vc.windowError(withTitle: title, description: message)
					} else {
						self?.shouldScrollToSelected = false
						self?.expandedSection = DependencyManager.shared.walletList.socialWallets.count > 0 ? hdWalletIndex+1 : hdWalletIndex
						self?.refresh(animate: true)
					}
				}
			}
		}
		
		let customPath = UIAction(title: "Add Custom Path", image: UIImage(named: "CustomPath")) { [weak self] action in
			
			// Fetch from store, otherwise it will be stale data
			if let meta = DependencyManager.shared.walletList.metadata(forAddress: walletMetadata.address) {
				self?.delegate?.performSegue(withIdentifier: "custom-path", sender: meta)
			}
		}
		
		let migrateLedger = UIAction(title: "Migrate To New Device", image: UIImage(named: "WalletLedgerMenu")) { [weak self] action in
			
			// Fetch from store, otherwise it will be stale data
			if let meta = DependencyManager.shared.walletList.metadata(forAddress: walletMetadata.address) {
				self?.delegate?.performSegue(withIdentifier: "migrate-ledger", sender: meta)
			}
		}
		
		let remove = UIAction(title: "Remove Wallet", image: UIImage(named: "Delete")) { [weak self] action in
			
			// Fetch from store, otherwise it will be stale data
			if let meta = DependencyManager.shared.walletList.metadata(forAddress: walletMetadata.address) {
				self?.delegate?.performSegue(withIdentifier: "remove", sender: meta)
			}
		}
		
		
		// Add different options depending on type of wallet
		var options: [[UIAction]] = [[edit, addAccount]]
		if walletMetadata.type == .ledger {
			options[0].append(contentsOf: [customPath, migrateLedger])
		}
		
		options[0].append(remove)
		return MenuViewController(actions: options, header: walletMetadata.hdWalletGroupName, alertStyleIndexes: [IndexPath(row: options[0].count-1, section: 0)], sourceViewController: vc)
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
	
	public static func askToConnectToLedgerIfNeeded(walletMetadata: WalletMetadata, completion: @escaping ((Bool) -> Void)) {
		guard walletMetadata.type == .ledger, LedgerService.shared.getConnectedDeviceUUID() == nil, let rootVc = UIApplication.shared.currentWindow?.rootViewController else {
			completion(true)
			return
		}
		
		var topMostVc = rootVc
		if let nav = rootVc as? UINavigationController, let last = nav.viewControllers.last {
			topMostVc = last
		}
		
		if let modal = rootVc.presentedViewController {
			topMostVc = modal
		}  else if let modal = topMostVc.presentedViewController {
			topMostVc = modal
		}
		
		if let menu = topMostVc as? MenuViewController, let parent = menu.presentingViewController {
			topMostVc = parent
		}
		
		guard let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) as? LedgerWallet else {
			rootVc.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			completion(false)
			return
		}
		
		topMostVc.alert(withTitle: "Connect?", andMessage: "Your Ledger device is not currently conencted. Would you like to connect now?",
						okText: "Connect",
						okAction: { action in
							connectLedger(rootVc: rootVc, uuid: wallet.ledgerUUID, completion: completion)
						},
						cancelText: "Cancel",
						cancelStyle: .destructive,
						cancelAction: { action in
							completion(false)
						})
	}
	
	public static func connectLedger(rootVc: UIViewController, uuid: String, completion: @escaping ((Bool) -> Void)) {
		LedgerService.shared.connectTo(uuid: uuid)
			.timeout(.seconds(10), scheduler: RunLoop.main, customError: {
				return KukaiError.knownErrorMessage("Timed out waiting for device to connect. Check device/bluetooth is turned on and try again")
			})
			.sink(onError: { error in
				rootVc.windowError(withTitle: "error".localized(), description: "\( error )")
				completion(false)
				staticBag = []
				
			}, onSuccess: { success in
				if !success {
					rootVc.windowError(withTitle: "error".localized(), description: "Unable to connect to device, please try again")
					completion(false)
				} else {
					completion(true)
				}
				
				staticBag = []
			})
			.store(in: &staticBag)
	}
}
