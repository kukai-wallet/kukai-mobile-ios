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
	let subheader: String?
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
			
			if let obj = item as? SendHeaderObj, obj.subheader == nil, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell", for: indexPath) as? ImageHeadingCell {
				cell.iconView.image = obj.icon
				cell.headingLabel.text = obj.title
				return cell
				
			} else if let obj = item as? SendHeaderObj, obj.subheader != nil, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell_subheading", for: indexPath) as? ImageHeadingCell {
				cell.iconView.image = obj.icon
				cell.headingLabel.text = obj.title
				cell.subheadingLabel?.text = obj.subheader
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
				
			} else if let _ = item as? CustomSeperatorData {
				return tableView.dequeueReusableCell(withIdentifier: "custom-seperator", for: indexPath)
				
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
			sectionData.append([SendHeaderObj(icon: walletImage, title: "Social Wallets", subheader: nil)])
			sectionData[sections.count-1].append(contentsOf: walletsToAdd)
		}
		
		
		// HD's
		handleGroupedData(metadataArray: wallets.hdWallets, walletImage: walletImage, sections: &sections, sectionData: &sectionData)
		
		
		// Linear
		walletsToAdd = []
		for metadata in wallets.linearWallets /*where metadata.address != selectedAddress*/ {
			let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
			walletsToAdd.append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
		}
		if walletsToAdd.count > 0 {
			sections.append(sections.count)
			sectionData.append([SendHeaderObj(icon: walletImage, title: "Legacy Wallets", subheader: nil)])
			sectionData[sections.count-1].append(contentsOf: walletsToAdd)
		}
		
		
		// Ledger
		handleGroupedData(metadataArray: wallets.ledgerWallets, walletImage: walletImage, sections: &sections, sectionData: &sectionData)
		
		// Add it all
		snapshot.appendSections(sections)
		for (index, data) in sectionData.enumerated() {
			snapshot.appendItems(data, toSection: index)
		}
		ds.apply(snapshot, animatingDifferences: animate)
		
		state = .success(nil)
	}
	
	private func handleGroupedData(metadataArray: [WalletMetadata], walletImage: UIImage, sections: inout [Int], sectionData: inout [[AnyHashable]]) {
		for (index, metadata) in metadataArray.enumerated() {
			sections.append(sections.count)
			
			if metadata.type == .ledger {
				sectionData.append([CustomSeperatorData(), SendHeaderObj(icon: walletImage, title: metadata.hdWalletGroupName ?? "", subheader: nil)])
			} else {
				sectionData.append([SendHeaderObj(icon: walletImage, title: metadata.hdWalletGroupName ?? "", subheader: nil)])
			}
			
			let isSectionExpanded = (expandedSection == sections.count-1)
			let walletMedia = TransactionService.walletMedia(forWalletMetadata: metadata, ofSize: .size_22)
			sectionData[sections.count-1].append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				
				// If child should be visible
				if isSectionExpanded || (!isSectionExpanded && childIndex < 2) {
					
					// Check if child is a custom derivation path, as those get extra heading
					if let customDerivation = childMetadata.customDerivationPath {
						sectionData[sections.count-1].append(SendHeaderObj(icon: walletImage, title: "Custom Path", subheader: "(\(customDerivation))"))
					}
					let walletMedia = TransactionService.walletMedia(forWalletMetadata: childMetadata, ofSize: .size_22)
					sectionData[sections.count-1].append(WalletObj(icon: walletMedia.image, title: walletMedia.title, subtitle: walletMedia.subtitle, address: metadata.address))
				}
			}
			
			// if there are more than 3 items total, display moreCell
			if metadata.children.count > 2 {
				let moreData = AccountsMoreObject(count: metadata.children.count-2, isExpanded: isSectionExpanded, hdWalletIndex: index)
				sectionData[sections.count-1].append(moreData)
			}
			
			if metadata.type == .ledger && index == metadataArray.count-1 {
				sectionData[sections.count-1].append(CustomSeperatorData())
			}
		}
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
