//
//  DiscoverViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import os.log

struct ShowMore: Hashable, Identifiable {
	let id = UUID()
}

class DiscoverViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private static let itemPerSection = 3
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var menu: MenuViewController? = nil
	var isVisible = false
	var featuredDelegate: DiscoverFeaturedCellDelegate? = nil
	var expandedSection: Int? = nil
	
	private var bag = [AnyCancellable]()
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressLoaded
			.dropFirst()
			.sink { [weak self] address in
				if DependencyManager.shared.selectedWalletAddress == address {
					if self?.isVisible == true {
						self?.refresh(animate: true)
					}
				}
			}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		tableView.register(UINib(nibName: "GhostnetWarningCell", bundle: nil), forCellReuseIdentifier: "GhostnetWarningCell")
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let obj = item as? MenuViewController, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceHeaderCell", for: indexPath) as? TokenBalanceHeaderCell {
				cell.setup(menuVC: obj)
				return cell
				
			} else if let obj = item as? DiscoverGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverFeaturedCell", for: indexPath) as? DiscoverFeaturedCell {
				cell.delegate = self?.featuredDelegate
				cell.setup(discoverGroup: obj)
				return cell
				
			} else if let obj = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverHeadingCell", for: indexPath) as? DiscoverHeadingCell {
				cell.titleLabel.text = obj
				return cell
				
			} else if let obj = item as? DiscoverItem, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverCell", for: indexPath) as? DiscoverCell {
				cell.titleLabel.text = obj.title
				cell.descriptionLabel.text = obj.description
				
				return cell
				
			} else if let _ = item as? ShowMore, let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverShowMoreCell", for: indexPath) as? DiscoverShowMoreCell {
				if self?.expandedSection == indexPath.section {
					cell.setOpen()
					
				} else {
					cell.setClosed()
				}
				
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
		
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		let groups = DependencyManager.shared.discoverService.items
		if groups.count == 0 { return }
		
		
		if DependencyManager.shared.currentNetworkType == .ghostnet {
			currentSnapshot.appendSections(Array(0..<groups.count))
			currentSnapshot.appendItems([GhostnetWarningCellObj(), menu, groups[0]], toSection: 0)
			
		} else {
			currentSnapshot.appendSections(Array(0..<groups.count))
			currentSnapshot.appendItems([menu, groups[0]], toSection: 0)
		}
		
		for (index, group) in groups.enumerated() {
			if index == 0 { continue }
			
			var itemsToAdd: [AnyHashable] = []
			itemsToAdd.append(group.title.uppercased())
			
			for (index2, item) in group.items.enumerated() {
				itemsToAdd.append(item)
				
				if index2 == (DiscoverViewModel.itemPerSection-1) && expandedSection != index {
					break
				}
			}
			
			if group.items.count > DiscoverViewModel.itemPerSection {
				itemsToAdd.append(ShowMore())
			}
			
			currentSnapshot.appendItems(itemsToAdd, toSection: index)
		}
		
		datasource.apply(currentSnapshot, animatingDifferences: animate)
	}
	
	func urlForDiscoverItem(atIndexPath: IndexPath) -> URL? {
		guard let obj = dataSource?.itemIdentifier(for: atIndexPath) as? DiscoverItem else {
			return nil
		}
		
		return obj.projectUrl
	}
	
	func isShowMoreOrLess(indexPath: IndexPath) -> Bool {
		guard let _ = dataSource?.itemIdentifier(for: indexPath) as? ShowMore else {
			return false
		}
		
		return true
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		let group = DependencyManager.shared.discoverService.items[indexPath.section]
		
		if group.items.count <= DiscoverViewModel.itemPerSection {
			return
		}
		
		if expandedSection == nil {
			expandedSection = indexPath.section
			self.openGroup(forTableView: tableView, atSection: indexPath.section)
			
		} else if expandedSection == indexPath.section {
			expandedSection = nil
			self.closeGroup(forTableView: tableView, atSection: indexPath.section)
			
		} else if let previousIndex = expandedSection, previousIndex != indexPath.section {
			self.openGroup(forTableView: tableView, atSection: indexPath.section)
			self.closeGroup(forTableView: tableView, atSection: previousIndex)
			expandedSection = indexPath.section
		}
		
		ds.apply(currentSnapshot, animatingDifferences: true)
	}
	
	private func openGroup(forTableView tableView: UITableView, atSection section: Int) {
		let numberOfCells = tableView.numberOfRows(inSection: section)
		let indexPath = IndexPath(row: numberOfCells-1, section: section)
		guard let cell = tableView.cellForRow(at: indexPath) as? DiscoverShowMoreCell, let item = dataSource?.itemIdentifier(for: indexPath) else {
			return
		}
		
		cell.setOpen()
		
		let group = DependencyManager.shared.discoverService.items[section]
		currentSnapshot.insertItems(Array(group.items[(DiscoverViewModel.itemPerSection)..<group.items.count]), beforeItem: item)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atSection section: Int) {
		let numberOfCells = tableView.numberOfRows(inSection: section)
		let indexPath = IndexPath(row: numberOfCells-1, section: section)
		guard let cell = tableView.cellForRow(at: indexPath) as? DiscoverShowMoreCell else {
			return
		}
		
		cell.setClosed()
		
		let group = DependencyManager.shared.discoverService.items[section]
		currentSnapshot.deleteItems(Array(group.items[(DiscoverViewModel.itemPerSection)..<group.items.count]))
	}
	
	func willDisplayImage(forIndexPath: IndexPath) -> URL? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? DiscoverItem else { return nil }
		
		Logger.app.info("Discover image loading: \(obj.squareLogoUri?.absoluteString)")
		return MediaProxyService.url(fromUri: obj.squareLogoUri, ofFormat: MediaProxyService.Format.small.rawFormat())
	}
}
