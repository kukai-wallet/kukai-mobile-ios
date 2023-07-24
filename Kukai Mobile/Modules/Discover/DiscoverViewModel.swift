//
//  DiscoverViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift

struct ShowMore: Hashable, Identifiable {
	let id = UUID()
}

class DiscoverViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var menu: MenuViewController? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? MenuViewController, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceHeaderCell", for: indexPath) as? TokenBalanceHeaderCell {
				cell.setup(menuVC: obj)
				return cell
				
			} else if let obj = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverHeadingCell", for: indexPath) as? DiscoverHeadingCell {
				cell.titleLabel.text = obj
				return cell
				
			} else if let obj = item as? DiscoverItem, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as? DiscoverCell {
				let updatedURL = MediaProxyService.url(fromUri: obj.thumbnailUri, ofFormat: .icon, keepGif: true)
				MediaProxyService.load(url: updatedURL, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken()) { size in
					cell.iconView.backgroundColor = .white
				}
				
				cell.titleLabel.text = obj.title
				cell.descriptionLabel.text = obj.description
				return cell
				
			} else if let _ = item as? ShowMore, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverShowMoreCell", for: indexPath) as? DiscoverShowMoreCell {
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
		
		DependencyManager.shared.discoverService.fetchItems { result in
			guard let _ = try? result.get() else {
				self.state = .failure(result.getFailure(), "Unable to fetch Discover items, try again")
				return
			}
			
			self.reloadData(animate: animate, datasource: ds)
			
			// Return success
			self.state = .success(nil)
		}
	}
	
	func reloadData(animate: Bool, datasource: UITableViewDiffableDataSource<Int, AnyHashable>) {
		guard let menu = self.menu else {
			return
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		if DependencyManager.shared.currentNetworkType == .testnet {
			snapshot.appendSections([0, 1])
			
			snapshot.appendItems([GhostnetWarningCellObj(), menu], toSection: 0)
			snapshot.appendItems([
				"Defi",
				DiscoverItem(id: UUID(), title: "WTZ", description: "Ghostnet version of Crunchy's wrapped XTZ", thumbnailUri: nil, projectURL: URL(string: "https://ghostnet.wtz.io/")),
				DiscoverItem(id: UUID(), title: "Quipuswap", description: "Ghostnet version of Quipuswap DEX", thumbnailUri: nil, projectURL: URL(string: "https://ghostnet.quipuswap.com/"))
			], toSection: 1)
			
		} else {
			let groups = DependencyManager.shared.discoverService.items
			
			snapshot.appendSections(Array(0..<groups.count))
			
			for (index, group) in groups.enumerated() {
				var itemsToAdd: [AnyHashable] = []
				
				if index == 0 {
					itemsToAdd.append(menu)
				}
				
				itemsToAdd.append(group.title)
				for (index2, item) in group.items.enumerated() {
					itemsToAdd.append(item)
					
					if index2 == 3 {
						break
					}
				}
				
				if group.items.count > 4 {
					itemsToAdd.append(ShowMore())
				}
				
				snapshot.appendItems(itemsToAdd, toSection: index)
			}
		}
		
		datasource.apply(snapshot, animatingDifferences: animate)
	}
	
	func urlForDiscoverItem(atIndexPath: IndexPath) -> URL? {
		/*
		let obj = dataSource?.itemIdentifier(for: atIndexPath)
		if let item = obj as? DiscoverItem {
			return URL(string: item.url)
		}
		*/
		return nil
	}
}
