//
//  SendToViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct SendHeaderObj: Hashable {
	let icon: UIImage
	let title: String
}

struct WalletObj: Hashable {
	let icon: UIImage?
	let title: String
	let subtitle: String?
	let address: String
}

struct NoContacts: Hashable {
	let id = UUID()
}

class SendToViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var expandedSection: Int? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? SendHeaderObj, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell", for: indexPath) as? ImageHeadingCell {
				cell.iconView.image = obj.icon
				cell.headingLabel.text = obj.title
				return cell
				
			} else if let obj = item as? WalletObj, let cell = tableView.dequeueReusableCell(withIdentifier: "AddressChoiceCell", for: indexPath) as? AddressChoiceCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle
				
				return cell
				
			} else if let _ = item as? NoContacts, let cell = tableView.dequeueReusableCell(withIdentifier: "NoContactsCell", for: indexPath) as? NoContactsCell {
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
		if !state.isLoading() {
			state = .loading
		}
		
		guard let ds = dataSource/*, let selectedAddress = DependencyManager.shared.selectedWalletAddress*/ else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		// Build arrays of data
		let wallets = DependencyManager.shared.walletList
		let walletImage = UIImage(named: "Wallet") ?? UIImage()
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		var sections: [Int] = []
		var sectionData: [[AnyHashable]] = []
		
		
		// TODO: contacts not enabled yet
		/*
		let contactsHeaderImage = UIImage(named: "Contacts") ?? UIImage()
		let contactsHeader = SendHeaderObj(icon: contactsHeaderImage, title: "Contacts")
		sections.append(sections.count)
		sectionData.append([contactsHeader, NoContacts()])
		*/
		
		
		
		// Social
		var walletsToAdd: [WalletObj] = []
		for metadata in wallets.socialWallets /*where metadata.address != selectedAddress*/ {
			let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
			walletsToAdd.append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
		}
		if walletsToAdd.count > 0 {
			sections.append(sections.count)
			sectionData.append([SendHeaderObj(icon: walletImage, title: "Social Wallets")])
			sectionData[sections.count-1].append(contentsOf: walletsToAdd)
		}
		
		
		// HD's
		for (index, metadata) in wallets.hdWallets.enumerated() {
			walletsToAdd = []
			/*
			if metadata.address == selectedAddress && metadata.children.count == 0 {
				continue
			}
			*/
			
			//if metadata.address != selectedAddress {
				let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
				walletsToAdd.append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
			//}
			
			let isSectionExpanded = (expandedSection == sections.count)
			var totalChildCount = 0
			for (_, childMetadata) in metadata.children.enumerated() {
				//if childMetadata.address == selectedAddress { continue }
				
				totalChildCount += 1
				
				if isSectionExpanded || (!isSectionExpanded && totalChildCount < 3) {
					let childWalletMedia = TransactionService.walletMedia(forWalletMetadata: childMetadata, ofSize: .size_22)
					walletsToAdd.append(WalletObj(icon: childWalletMedia.image, title: childWalletMedia.title, subtitle: childWalletMedia.subtitle, address: childMetadata.address))
				}
			}
			
			if walletsToAdd.count > 0 {
				sections.append(sections.count)
				sectionData.append([SendHeaderObj(icon: walletImage, title: metadata.hdWalletGroupName ?? "")])
				sectionData[sections.count-1].append(contentsOf: walletsToAdd)
			}
			
			// if there are more than 3 items total, display moreCell
			if totalChildCount > 2 {
				let moreData = AccountsMoreObject(count: totalChildCount-2, isExpanded: isSectionExpanded, hdWalletIndex: index)
				sectionData[sections.count-1].append(moreData)
			}
		}
		
		// Linear
		walletsToAdd = []
		for metadata in wallets.linearWallets /*where metadata.address != selectedAddress*/ {
			let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
			walletsToAdd.append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
		}
		if walletsToAdd.count > 0 {
			sections.append(sections.count)
			sectionData.append([SendHeaderObj(icon: walletImage, title: "Legacy Wallets")])
			sectionData[sections.count-1].append(contentsOf: walletsToAdd)
		}
		
		
		// Ledger
		walletsToAdd = []
		for metadata in wallets.ledgerWallets /*where metadata.address != selectedAddress*/ {
			let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
			walletsToAdd.append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
		}
		if walletsToAdd.count > 0 {
			sections.append(sections.count)
			sectionData.append([SendHeaderObj(icon: walletImage, title: "Ledger Wallets")])
			sectionData[sections.count-1].append(contentsOf: walletsToAdd)
		}
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		ds.apply(snapshot, animatingDifferences: animate)
		
		state = .success(nil)
	}
	
	func walletObj(forIndexPath indexPath: IndexPath) -> WalletObj? {
		guard indexPath.row > 0 else { return nil }
		
		return dataSource?.itemIdentifier(for: indexPath) as? WalletObj
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
		
		refresh(animate: true)
		return true
	}
}
