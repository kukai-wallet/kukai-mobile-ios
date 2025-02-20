//
//  NetworkChooserViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/02/2025.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct NetworkChoiceObj: Hashable {
	let title: String
	let networkType: TezosNodeClientConfig.NetworkType?
	let description: String
	let isMore: Bool
	let isHeading: Bool
}

class NetworkChooserViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	public var selectedIndex: IndexPath = IndexPath(row: 0, section: 0)
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			if let obj = item.base as? NetworkChoiceObj, obj.isHeading, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuHeadingCell", for: indexPath) as? SideMenuHeadingCell {
				cell.titleLabel.text = obj.title
				return cell
				
			} else if let obj = item.base as? NetworkChoiceObj, !obj.isMore, let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkChoiceCell_single", for: indexPath) as? NetworkChoiceCell {
				cell.networkLabel.text = obj.title
				cell.descriptionLabel.text = obj.description
				return cell
				
			} else if let obj = item.base as? NetworkChoiceObj, obj.isMore, let cell = tableView.dequeueReusableCell(withIdentifier: "NetworkChoiceCell_more", for: indexPath) as? NetworkChoiceCell {
				cell.networkLabel.text = obj.title
				cell.descriptionLabel.text = obj.description
				cell.selectable = false
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			self.state = .failure(KukaiError.unknown(), "Unknown error")
			return
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0, 1])
		
		snapshot.appendItems([
			.init(NetworkChoiceObj(title: "Basic", networkType: nil, description: "", isMore: false, isHeading: true)),
			.init(NetworkChoiceObj(title: "Mainnet", networkType: .mainnet, description: "Live network with real XTZ and Tokens with real values", isMore: false, isHeading: false)),
			.init(NetworkChoiceObj(title: "Ghostnet", networkType: .ghostnet, description: "A permanent test network running the lastest Tezos protocol, with fake XTZ and tokens with no monetary value", isMore: false, isHeading: false))
		], toSection: 0)
		
		snapshot.appendItems([
			.init(NetworkChoiceObj(title: "Advanced", networkType: nil, description: "", isMore: false, isHeading: true)),
			.init(NetworkChoiceObj(title: "Protocolnet", networkType: .protocolnet, description: "A short-lived test network currently running the XXXXX protocol, with fake XTZ and tokens with no monetary value", isMore: false, isHeading: false)),
			.init(NetworkChoiceObj(title: "Nextnet", networkType: .nextnet, description: "A short-lived test network running the next unreleased protocol, with fake XTZ and tokens with no monetary value", isMore: false, isHeading: false)),
			.init(NetworkChoiceObj(title: "Experimental", networkType: .experimental, description: "For advanced users only, such as protocol developers. Enter your own RPC URL and optionally a TzKT URL", isMore: true, isHeading: false))
		], toSection: 1)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		
		// Return success
		selectedIndexFromNetworkSelection()
		self.state = .success(nil)
	}
	
	func networkTypeFromIndex(indexPath: IndexPath) -> TezosNodeClientConfig.NetworkType? {
		guard let ds = dataSource else {
			return nil
		}
		
		return (ds.itemIdentifier(for: indexPath)?.base as? NetworkChoiceObj)?.networkType
	}
	
	// Figure out selected index, no matter what values are added/changed
	func selectedIndexFromNetworkSelection() {
		guard let ds = dataSource else {
			return
		}
		
		let snapshot = ds.snapshot()
		let currentNetwork = DependencyManager.shared.currentNetworkType
		let sectionInfo = snapshot.sectionIdentifiers
		for (indexSection, item) in sectionInfo.enumerated() {
			let items = snapshot.itemIdentifiers(inSection: item)
			for (indexRow, item) in items.enumerated() {
				if currentNetwork == (item.base as? NetworkChoiceObj)?.networkType {
					selectedIndex = IndexPath(row: indexRow, section: indexSection)
					return
				}
			}
		}
	}
}
