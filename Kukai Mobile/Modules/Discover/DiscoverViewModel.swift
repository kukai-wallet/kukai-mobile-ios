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
	var discoverItems: [DiscoverItem] = []
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let discoverItem = item as? DiscoverItem, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as? DiscoverCell {
				cell.headingLabel.text = discoverItem.heading
				cell.iconView.image = UIImage(named: discoverItem.imageName)
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
		
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate data source"), "Unable to locate data source")
			return
		}
		
		self.reloadData(animate: animate, datasource: ds)
			
		// Return success
		self.state = .success(nil)
	}
	
	func reloadData(animate: Bool, datasource: UITableViewDiffableDataSource<Int, AnyHashable>) {
		self.discoverItems = [
			DiscoverItem(heading: "COLLECTIBLES", imageName: "discover-gap", url: "https://www.gap.com/nft/"),
			DiscoverItem(heading: "COLLECTIBLES", imageName: "discover-mooncakes", url: "https://www.mooncakes.fun")
		]
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		snapshot.appendItems(self.discoverItems, toSection: 0)
		
		datasource.apply(snapshot, animatingDifferences: animate)
	}
	
	func urlForDiscoverItem(atIndexPath: IndexPath) -> URL? {
		if atIndexPath.section == 0, atIndexPath.row < discoverItems.count  {
			return URL(string: discoverItems[atIndexPath.row].url)
		}
	
		return nil
	}
}
