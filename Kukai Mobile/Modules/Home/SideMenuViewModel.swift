//
//  SideMenuViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit
import KukaiCoreSwift
import OSLog

struct WalletData: Hashable {
	let type: WalletType
	let authProvider: TorusAuthProvider?
	let username: String?
	let address: String
	let selected: Bool
}


class SideMenuViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = WalletData
	
	var dataSource: UITableViewDiffableDataSource<Int, WalletData>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if indexPath.row != 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSubCell", for: indexPath) as? AccountSubCell {
				cell.setup(address: item.address, menu: self?.menuFor(walletData: item, indexPath: indexPath))
				cell.setBorder(item.selected)
				return cell
				
			} else if item.type == .torus, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSocialCell", for: indexPath) as? AccountSocialCell {
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
			state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		let selectedAddress = DependencyManager.shared.selectedWallet?.address
		
		let wallets = WalletCacheService().fetchWallets() ?? []
		var snapshot = NSDiffableDataSourceSnapshot<Int, WalletData>()
		snapshot.appendSections(Array(0...wallets.count))
		
		for (index, wallet) in wallets.enumerated() {
			
			var username: String? = nil
			var authProvider: TorusAuthProvider? = nil
			
			if wallet.type == .torus {
				username = (wallet as? TorusWallet)?.socialUserId
				authProvider = (wallet as? TorusWallet)?.authProvider
			}
			
			let data = WalletData(type: wallet.type, authProvider: authProvider, username: username, address: wallet.address, selected: wallet.address == selectedAddress)
			
			snapshot.appendItems([data], toSection: index)
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
			case .none:
				return nil
		}
	}
	
	func menuFor(walletData: WalletData, indexPath: IndexPath) -> UIMenu {
		var options: [UIAction] = []
		
		if walletData.type == .hd {
			options.append(
				UIAction(title: "Add Account", image: UIImage(systemName: "plus.square.on.square"), identifier: nil, handler: { action in
					print("Tapped Add account")
				})
			)
		}
		
		options.append(
			UIAction(title: "Delete", image: UIImage(systemName: "delete.left.fill"), identifier: nil) { [weak self] action in
				var deletingSelected = false
				
				if walletData.address == DependencyManager.shared.selectedWallet?.address {
					deletingSelected = true
				}
				
				if WalletCacheService().deleteWallet(withAddress: walletData.address, parentHDWallet: nil) {
					if deletingSelected && WalletCacheService().fetchPrimaryWallet() != nil {
						DependencyManager.shared.selectedWalletIndex = 0
					}
					
					self?.refresh(animate: true)
					
				} else {
					self?.state = .failure(ErrorResponse.unknownError(), "Unable to delete wallet from cache")
				}
			}
		)
		
		return UIMenu(title: "Actions", image: nil, identifier: nil, options: [], children: options)
	}
}
