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
}


class SideMenuViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = WalletData
	
	var dataSource: UITableViewDiffableDataSource<Int, WalletData>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		let selectedAddress = DependencyManager.shared.selectedWallet?.address
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if indexPath.row != 0, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSubCell", for: indexPath) as? AccountSubCell {
				cell.addressLabel.text = item.address
				cell.setBorder(item.address == selectedAddress)
				return cell
				
			} else if item.type == .torus, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountSocialCell", for: indexPath) as? AccountSocialCell {
				cell.iconView.image = self?.imageForAuthProvider(item.authProvider)
				cell.usernameLabel.text = item.username
				cell.addressLabel.text = item.address
				cell.setBorder(item.address == selectedAddress)
				return cell
				
			} else if let cell = tableView.dequeueReusableCell(withIdentifier: "AccountBasicCell", for: indexPath) as? AccountBasicCell {
				cell.addressLabel.text = item.address
				cell.setBorder(item.address == selectedAddress)
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
			
			let data = WalletData(type: wallet.type, authProvider: authProvider, username: username, address: wallet.address)
			
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
}
