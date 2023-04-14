//
//  AccountsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift
import OSLog

/*
struct WalletData: Hashable {
	let type: WalletType
	let authProvider: TorusAuthProvider?
	let username: String?
	let address: String
	let selected: Bool
	let isChild: Bool
	let parentAddress: String?
}
*/

class AccountsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	public var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let obj = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsSectionHeaderCell", for: indexPath) as? AccountsSectionHeaderCell {
				cell.headingLabel.text = obj
				return cell
				
			} else if let obj = item as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountItemCell", for: indexPath) as? AccountItemCell {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: obj, ofSize: .size_22)
				cell.iconView.image = walletMedia.image
				cell.titleLabel.text = walletMedia.title
				cell.subtitleLabel.text = walletMedia.subtitle
				
				if obj.address == DependencyManager.shared.selectedWalletAddress {
					self?.selectedIndex = indexPath
				}
				
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
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		var sections: [Int] = []
		var sectionData: [[AnyHashable]] = []
		
		// Social
		if wallets.socialWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Social Wallets"])
		}
		for metadata in wallets.socialWallets {
			sectionData[sections.count-1].append(metadata)
		}
		
		
		// HD's
		for (index, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			sectionData.append(["HD Wallet \(index + 1)"])
			
			sectionData[sections.count-1].append(metadata)
			
			for childMetadata in metadata.children {
				sectionData[sections.count-1].append(childMetadata)
			}
		}
		
		
		// Linear
		if wallets.linearWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Legacy Wallets"])
		}
		for metadata in wallets.linearWallets {
			sectionData[sections.count-1].append(metadata)
		}
		
		
		// Ledger
		if wallets.ledgerWallets.count > 0 {
			sections.append(sections.count)
			sectionData.append(["Ledger Wallets"])
		}
		for metadata in wallets.ledgerWallets {
			sectionData[sections.count-1].append(metadata)
		}
		
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	
	
	
	
	/*typealias SectionEnum = Int
	typealias CellDataType = WalletData
	
	var dataSource: UITableViewDiffableDataSource<Int, WalletData>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if indexPath.row != 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSubCell", for: indexPath) as? AccountSubCell {
				cell.setup(address: item.address, menu: self?.menuFor(walletData: item, indexPath: indexPath))
				cell.setBorder(item.selected)
				return cell
				
			} else if item.type == .social, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSocialCell", for: indexPath) as? AccountSocialCell {
				cell.setup(image: self?.imageForAuthProvider(item.authProvider), username: item.username ?? "", address: item.address, menu: self?.menuFor(walletData: item, indexPath: indexPath))
				cell.setBorder(item.selected)
				return cell
				
			} else if let cell = tableView.dequeueReusableCell(withIdentifier: "AccountBasicCell", for: indexPath) as? AccountBasicCell {
				cell.setup(address: item.address, menu: self?.menuFor(walletData: item, indexPath: indexPath))
				cell.setBorder(item.selected)
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
		
		let selectedAddress = DependencyManager.shared.selectedWalletAddress
		
		let wallets = DependencyManager.shared.walletList
		var snapshot = NSDiffableDataSourceSnapshot<Int, WalletData>()
		snapshot.appendSections(Array(0...wallets.count))
		
		for (index, wallet) in wallets.enumerated() {
			
			if wallet.type == .social {
				let username = wallet.displayName
				let data = WalletData(type: wallet.type, authProvider: wallet.socialType, username: username, address: wallet.address, selected: wallet.address == selectedAddress, isChild: false, parentAddress: nil)
				snapshot.appendItems([data], toSection: index)
				
			} else if wallet.type == .hd {
				var data: [WalletData] = [WalletData(type: wallet.type, authProvider: nil, username: nil, address: wallet.address, selected: wallet.address == selectedAddress, isChild: false, parentAddress: nil)]
				for child in wallet.children {
					data.append(WalletData(type: .hd, authProvider: nil, username: nil, address: child.address, selected: child.address == selectedAddress, isChild: true, parentAddress: wallet.address))
				}
				snapshot.appendItems(data, toSection: index)
				
			} else {
				let data = WalletData(type: wallet.type, authProvider: nil, username: nil, address: wallet.address, selected: wallet.address == selectedAddress, isChild: false, parentAddress: nil)
				snapshot.appendItems([data], toSection: index)
			}
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(nil)
	}
	
	func imageForAuthProvider(_ provider: TorusAuthProvider?) -> UIImage? {
		switch provider {
			case .apple:
				return UIImage(systemName: "xmark.octagon")
			case .twitter:
				return UIImage(systemName: "xmark.octagon")
			case .google:
				return UIImage(systemName: "xmark.octagon")
			case .reddit:
				return UIImage(systemName: "xmark.octagon")
			case .facebook:
				return UIImage(systemName: "xmark.octagon")
			default:
				return UIImage(systemName: "xmark.octagon")
		}
	}
	
	func menuFor(walletData: WalletData, indexPath: IndexPath) -> UIMenu {
		var options: [UIAction] = []
		
		if walletData.type == .hd && indexPath.row == 0 {
			options.append(
				UIAction(title: "Add Account", image: UIImage(systemName: "plus.square.on.square"), identifier: nil, handler: { [weak self] action in
					guard let hdWallet = WalletCacheService().fetchWallet(forAddress: walletData.address) as? HDWallet else {
						self?.state = .failure(KukaiError.unknown(), "Unable to add new wallet")
						return
					}
					
					let numberOfChildren = DependencyManager.shared.walletList[indexPath.section].children.count
					if let child = hdWallet.createChild(accountIndex: numberOfChildren+1), WalletCacheService().cache(wallet: child, childOfIndex: indexPath.section) {
						DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
						self?.refresh(animate: true)
						
					} else {
						self?.state = .failure(KukaiError.unknown(), "Unable to add new wallet")
					}
				})
			)
		}
		
		options.append(
			UIAction(title: "Delete", image: UIImage(systemName: "delete.left.fill"), identifier: nil) { [weak self] action in
				var deletingSelected = false
				
				if walletData.address == DependencyManager.shared.selectedWalletAddress {
					deletingSelected = true
				}
				
				if WalletCacheService().deleteWallet(withAddress: walletData.address, parentIndex: walletData.isChild ? indexPath.section : nil) {
					DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
					
					// If we are deleting selected, we need to select another wallet, but not if we deleted the last one
					if deletingSelected && DependencyManager.shared.walletList.count > 0 {
						DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: 0, child: nil)
					}
					
					self?.refresh(animate: true)
					
				} else {
					self?.state = .failure(KukaiError.unknown(), "Unable to delete wallet from cache")
				}
			}
		)
		
		return UIMenu(title: "Actions", image: nil, identifier: nil, options: [], children: options)
	}*/
}
