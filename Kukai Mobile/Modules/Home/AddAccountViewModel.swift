//
//  AddAccountViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/05/2024.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import Combine
import OSLog

class AddAccountViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	var selectedIndex: IndexPath = IndexPath(row: -1, section: -1)
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			let identifier = indexPath.row == 0 ? "AccountItemCell" : "AccountSubItemCell"
			if let obj = item.base as? WalletMetadata, let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? AccountItemCell {
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
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		
		var sections: [Int] = []
		var sectionData: [[AnyHashableSendable]] = []
		
		// HD's
		for (_, metadata) in wallets.hdWallets.enumerated() {
			sections.append(sections.count)
			
			var items: [AnyHashableSendable] = [.init(metadata)]
			for (_, childMetadata) in metadata.children.prefix(3).enumerated() {
				items.append(.init(childMetadata))
			}
			sectionData.append(items)
		}
		
		// Ledger
		for (_, metadata) in wallets.ledgerWallets.enumerated() {
			sectionData[sections.count-1].append(.init(metadata))
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
		return dataSource?.itemIdentifier(for: indexPath)?.base as? WalletMetadata
	}
	
	public static func isPreviousAccountUsed(forAddress address: String, forceMainnet: Bool, completion: @escaping ((Bool) -> Void)) {
		var metadataToCheck = DependencyManager.shared.walletList.metadata(forAddress: address)
		if (metadataToCheck?.children.count ?? 0) > 0, let last = metadataToCheck?.children.last {
			metadataToCheck = last
		}
		
		guard let meta = metadataToCheck else {
			completion(false)
			return
		}
		
		WalletManagementService.isUsedAccount(address: meta.address, forceMainnet: forceMainnet, completion: completion)
	}
	
	public static func addAccount(forMetadata walletMetadata: WalletMetadata, hdWalletIndex: Int, forceMainnet: Bool, completion: @escaping ((String?, String?) -> Void)) {
		
		AddAccountViewModel.isPreviousAccountUsed(forAddress: walletMetadata.address, forceMainnet: forceMainnet, completion: { isUsed in
			guard isUsed else {
				completion("error-previous-account-title".localized(), "error-previous-account-empty".localized())
				return
			}
			
			guard let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) else {
				completion("error".localized(), "error-cant-add-account".localized())
				return
			}
			
			switch wallet.type {
				case .regular, .regularShifted, .social:
					completion("error".localized(), "error-cant-add-account".localized())
					
				case .hd:
					addAccountForHD(wallet: wallet, walletMetadata: walletMetadata, walletIndex: hdWalletIndex, completion: completion)
					
				case .ledger:
					addAccountForLedger(wallet: wallet, walletMetadata: walletMetadata, walletIndex: hdWalletIndex, customPath: nil, completion: completion)
			}
		})
	}
	
	public static func addAccountForHD(wallet: Wallet, walletMetadata: WalletMetadata, walletIndex: Int, completion: @escaping ((String?, String?) -> Void)) {
		guard let wallet = wallet as? HDWallet,
			  let newChild = wallet.createChild(accountIndex: walletMetadata.children.count+1) else {
			completion("error".localized(), "error-cant-add-account".localized())
			return
		}
		
		WalletManagementService.cacheNew(wallet: newChild, forChildOfIndex: walletIndex, backedUp: false, markSelected: false) { errorString in
			if let eString = errorString {
				completion("error".localized(), eString)
			} else {
				completion(nil, nil)
			}
		}
	}
	
	public static func addAccountForLedger(wallet: Wallet, walletMetadata: WalletMetadata, walletIndex: Int, customPath: String?, completion: @escaping ((String?, String?) -> Void)) {
		guard let wallet = wallet as? LedgerWallet else {
			DispatchQueue.main.async { completion("error".localized(), "error-cant-add-account".localized()) }
			return
		}
		
		let lastChildDerivationPath = walletMetadata.children.last?.derivationPath
		let lastPathComponents = lastChildDerivationPath?.components(separatedBy: "/") ?? []
		var lastAccountIndex: Int? = nil
		if lastPathComponents.count > 3 {
			var sanitisedAccountIndex = lastPathComponents[3]
			sanitisedAccountIndex = sanitisedAccountIndex.replacingOccurrences(of: "\'", with: "")
			lastAccountIndex = Int(sanitisedAccountIndex)
		}
		
		guard let previousAccountIndex = lastAccountIndex else {
			DispatchQueue.main.async { completion("error".localized(), "error-ledger-add-new-path".localized()) }
			return
		}
		
		let newDerivationPath = customPath ?? HD.defaultDerivationPath(withAccountIndex: previousAccountIndex+1)
		Task {
			let response = await LedgerService.shared.getAddress(forDerivationPath: newDerivationPath, verify: false)
			
			guard let res = try? response.get(),
				  let newChild = LedgerWallet(address: res.address, publicKey: res.publicKey, derivationPath: newDerivationPath, curve: .ed25519, ledgerUUID: wallet.ledgerUUID) else {
				DispatchQueue.main.async { completion("error".localized(), "error-cant-add-account".localized()) }
				return
			}
			
			WalletManagementService.cacheNew(wallet: newChild, forChildOfIndex: walletIndex, backedUp: false, markSelected: false) { errorString in
				if let eString = errorString {
					DispatchQueue.main.async { completion("error".localized(), eString) }
				} else {
					DispatchQueue.main.async { completion(nil, nil) }
				}
			}
		}
	}
}
