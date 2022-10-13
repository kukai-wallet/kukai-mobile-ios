//
//  CollectiblesViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class CollectiblesViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var isPresentedForSelectingToken = false
	var isVisible = false
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil && self?.isVisible == true {
					self?.refresh(animate: true)
				}
			}
	}
	
	deinit {
		accountDataRefreshedCancellable?.cancel()
	}
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTGroupCell", for: indexPath) as? NFTGroupCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				cell.titleLabel.text = obj.name
				
				return cell
				
			} else if let obj = item as? NFT, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTItemCell", for: indexPath) as? NFTItemCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				cell.setup(title: obj.name, balance: obj.balance)
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections(Array(0..<DependencyManager.shared.balanceService.account.nfts.count))
		
		for (index, nftGroup) in DependencyManager.shared.balanceService.account.nfts.enumerated() {
			currentSnapshot.appendItems([nftGroup], toSection: index)
		}
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		if expandedIndex == nil {
			expandedIndex = indexPath
			self.openGroup(forTableView: tableView, atIndexPath: indexPath)
			
		} else if expandedIndex == indexPath {
			expandedIndex = nil
			self.closeGroup(forTableView: tableView, atIndexPath: indexPath)
			
		} else if let previousIndex = expandedIndex, previousIndex != indexPath {
			self.openGroup(forTableView: tableView, atIndexPath: indexPath)
			self.closeGroup(forTableView: tableView, atIndexPath: previousIndex)
			expandedIndex = indexPath
		}
		
		ds.apply(currentSnapshot, animatingDifferences: true)
	}
	
	private func openGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? NFTGroupCell {
			cell.setOpen()
		}
		
		let nftGroup = DependencyManager.shared.balanceService.account.nfts[indexPath.section]
		
		currentSnapshot.insertItems(nftGroup.nfts ?? [], afterItem: nftGroup)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? NFTGroupCell {
			cell.setClosed()
		}
		
		let nftGroup = DependencyManager.shared.balanceService.account.nfts[indexPath.section]
		
		currentSnapshot.deleteItems(nftGroup.nfts ?? [])
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		return DependencyManager.shared.balanceService.account.nfts[atIndexPath.section].nfts?[atIndexPath.row-1]
	}
}
