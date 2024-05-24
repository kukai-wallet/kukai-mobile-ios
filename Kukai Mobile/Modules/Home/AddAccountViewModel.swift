//
//  AddAccountViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/05/2024.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class AddAccountViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var selectedIndex: IndexPath = IndexPath(row: -1, section: -1)
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			let identifier = indexPath.row == 0 ? "AccountItemCell" : "AccountSubItemCell"
			if let obj = item as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AccountItemCell {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: obj, ofSize: .size_22)
				cell.iconView.image = walletMedia.image
				cell.titleLabel.text = walletMedia.title
				cell.subtitleLabel.text = walletMedia.subtitle
				
				if indexPath.row != 0 {
					cell.checkmarkAvailable = false
					cell.checkedImageView?.isHidden = true
				} else {
					cell.checkmarkAvailable = true
					cell.checkedImageView?.isHidden = false
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
		
		// HD's
		for (_, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			
			var items: [AnyHashable] = [metadata]
			for (_, childMetadata) in metadata.children.prefix(3).enumerated() {
				items.append(childMetadata)
			}
			sectionData.append(items)
		}
		
		// Ledger
		for (_, metadata) in wallets.ledgerWallets.enumerated() {
			sectionData[sections.count-1].append(metadata)
		}
		
		
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		
		ds.apply(snapshot, animatingDifferences: true)
		self.state = .success(nil)
	}
	
	func metadataFor(indexPath: IndexPath) -> WalletMetadata? {
		return dataSource?.itemIdentifier(for: indexPath) as? WalletMetadata
	}
	
	public static func isPreviousAccountUsed(forAddress address: String, completion: @escaping ((Bool) -> Void)) {
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
	
	public static func addAccount(forMetadata walletMetadata: WalletMetadata, hdWalletIndex: Int, completion: @escaping ((String?, String?) -> Void)) {
		
		AddAccountViewModel.isPreviousAccountUsed(forAddress: walletMetadata.address, completion: { isUsed in
			guard isUsed else {
				completion("error-previous-account-title".localized(), "error-previous-account-empty".localized())
				return
			}
			
			guard let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) as? HDWallet,
				  let newChild = wallet.createChild(accountIndex: walletMetadata.children.count+1) else {
				completion("error".localized(), "error-cant-add-account".localized())
				return
			}
			
			WalletManagementService.cacheNew(wallet: newChild, forChildOfIndex: hdWalletIndex, backedUp: false, markSelected: false) { errorString in
				if let eString = errorString {
					completion("error".localized(), eString)
				} else {
					completion(nil, nil)
				}
			}
		})
	}
}
