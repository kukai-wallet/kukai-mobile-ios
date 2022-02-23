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
	
	private let balanceService = DependencyManager.shared.balanceService
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	public var isPresentedForSelectingToken = false
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTGroupCell", for: indexPath) as? NFTGroupCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				cell.titleLabel.text = obj.name
				
				return cell
				
			} else if let obj = item as? NFT, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTItemCell", for: indexPath) as? NFTItemCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.iconView.frame.size)
				cell.titleLabel.text = obj.name
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections(Array(0..<balanceService.account.nfts.count))
		
		for (index, nftGroup) in balanceService.account.nfts.enumerated() {
			currentSnapshot.appendItems([nftGroup], toSection: index)
		}
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	func openOrCloseGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
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
		
		let nftGroup = balanceService.account.nfts[indexPath.section]
		
		currentSnapshot.insertItems(nftGroup.nfts ?? [], afterItem: nftGroup)
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? NFTGroupCell {
			cell.setClosed()
		}
		
		let nftGroup = balanceService.account.nfts[indexPath.section]
		
		currentSnapshot.deleteItems(nftGroup.nfts ?? [])
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		return DependencyManager.shared.balanceService.account.nfts[atIndexPath.section].nfts?[atIndexPath.row-1]
	}
}
