//
//  DiscoverViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift

struct DiscoverItem: Hashable {
	let heading: String
	let imageName: String
	let url: String
}

class DiscoverViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let discoverItem = item as? DiscoverItem, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as? DiscoverCell {
				cell.headingLabel.text = discoverItem.heading
				cell.iconView.image = UIImage(named: discoverItem.imageName)
				return cell
				
			} else {
				return tableView.dequeueReusableCell(withIdentifier: "GhostnetWarningCell", for: indexPath)
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate data source"), "Unable to locate data source")
			return
		}
		
		self.reloadData(animate: animate, datasource: ds)
			
		// Return success
		self.state = .success(nil)
	}
	
	func reloadData(animate: Bool, datasource: UITableViewDiffableDataSource<Int, AnyHashable>) {
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		if DependencyManager.shared.currentNetworkType == .testnet {
			snapshot.appendItems([
				GhostnetWarningCellObj(),
				//DiscoverItem(heading: "WTZ - Ghostnet wrapped XTZ", imageName: "missingThumb", url: "https://ghostnet.wtz.io/"),
				//DiscoverItem(heading: "Quipuswap - Ghostnet DEX", imageName: "missingThumb", url: "https://ghostnet.quipuswap.com/")
			], toSection: 0)
			
		} else {
			snapshot.appendItems([
				//DiscoverItem(heading: "The GAP", imageName: "missingThumb", url: "https://www.gap.com/nft/"),
				//DiscoverItem(heading: "Mooncakes", imageName: "missingThumb", url: "https://www.mooncakes.fun")
			], toSection: 0)
		}
		
		snapshot.appendItems([], toSection: 0)
		
		datasource.apply(snapshot, animatingDifferences: animate)
	}
	
	func urlForDiscoverItem(atIndexPath: IndexPath) -> URL? {
		
		let obj = dataSource?.itemIdentifier(for: atIndexPath)
		if let item = obj as? DiscoverItem {
			return URL(string: item.url)
		}
	
		return nil
	}
}
