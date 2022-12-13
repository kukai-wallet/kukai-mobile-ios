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

struct ControlGroupData: Hashable {
	let id = UUID()
}

struct SpecialGroupData: Hashable {
	let imageName: String
	let title: String
	let count: Int
	let isShowcase: Bool
	let nfts: [NFT]
}


class CollectiblesViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	private var expandedIndex: IndexPath? = nil
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	var layout: UICollectionViewLayout = UICollectionViewFlowLayout()
	var isVisible = false
	var isSearching = false
	
	weak var validatorTextfieldDelegate: ValidatorTextFieldDelegate? = nil
	
	
	
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
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectiblesSearchCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesSearchCell")
		collectionView.register(UINib(nibName: "CollectibleSpecialGroupCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleSpecialGroupCell")
		collectionView.register(UINib(nibName: "CollectiblesListGroupCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesListGroupCell")
		collectionView.register(UINib(nibName: "CollectiblesListItemCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesListItemCell")
		collectionView.register(UINib(nibName: "CollectiblesSearchResultCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesSearchResultCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			if let _ = item as? ControlGroupData, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator()
				cell.searchBar.validatorTextFieldDelegate = self?.validatorTextfieldDelegate
				return cell
				
			} else if let obj = item as? SpecialGroupData, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleSpecialGroupCell", for: indexPath) as? CollectibleSpecialGroupCell {
				cell.iconView.image = UIImage(named: obj.imageName) ?? UIImage()
				cell.titleLabel.text = obj.title
				cell.countLabel.text = obj.count.description
				cell.moreButton.isHidden = !obj.isShowcase
				return cell
				
			} else if let obj = item as? Token, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListGroupCell", for: indexPath) as? CollectiblesListGroupCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				
				if let alias = obj.name {
					cell.titleLabel.text = alias
					cell.titleLabel.lineBreakMode = .byTruncatingTail
				} else {
					cell.titleLabel.text = obj.tokenContractAddress
					cell.titleLabel.lineBreakMode = .byTruncatingMiddle
				}
				
				cell.countLabel.text = obj.nfts?.count.description ?? ""
				return cell
				
			} else if let obj = item as? NFT, self?.isSearching == false, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListItemCell", for: indexPath) as? CollectiblesListItemCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				cell.setup(title: obj.name, balance: obj.balance)
				cell.subTitleLabel.text = obj.parentAlias ?? obj.parentContract
				
				return cell
				
			} else if let obj = item as? NFT, self?.isSearching == true, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchResultCell", for: indexPath) as? CollectiblesSearchResultCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				cell.setup(title: obj.name, balance: obj.balance)
				cell.subTitleLabel.text = obj.parentAlias ?? obj.parentContract
				
				return cell
				
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListGroupCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		let l = CollectibleListLayout()
		l.delegate = self
		layout = l
		
		
		var hashableData: [[AnyHashable]] = [[ControlGroupData()]]
		
		if let firstNFT = DependencyManager.shared.balanceService.account.nfts.first?.nfts?.first {
			var duplicateCopy = firstNFT
			
			duplicateCopy.duplicateID = 1
			hashableData.append( [SpecialGroupData(imageName: "star-fill", title: "Favorites", count: 1, isShowcase: false, nfts: [duplicateCopy])] )
			
			duplicateCopy.duplicateID = 2
			hashableData.append( [SpecialGroupData(imageName: "collectible-group-recents", title: "Recents", count: 1, isShowcase: false, nfts: [duplicateCopy])] )
			
			duplicateCopy.duplicateID = 3
			hashableData.append( [SpecialGroupData(imageName: "collectible-group-showcase", title: "Showcase", count: 1, isShowcase: true, nfts: [duplicateCopy])] )
		}
		
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			hashableData.append( [nftGroup] )
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections(Array(0..<(hashableData.count) ))
		
		for (index, item) in hashableData.enumerated() {
			currentSnapshot.appendItems(item, toSection: index)
		}
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	
	
	// MARK: UI functions
	
	func shouldOpenCloseForIndexPathTap(_ indexPath: IndexPath) -> Bool {
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[indexPath.row]
		
		if item is SpecialGroupData {
			return true
			
		} else if item is Token {
			return true
			
		} else {
			return false
		}
	}
	
	func openOrCloseGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		if expandedIndex == nil {
			expandedIndex = indexPath
			self.openGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			
		} else if expandedIndex == indexPath {
			expandedIndex = nil
			self.closeGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			
		} else if let previousIndex = expandedIndex, previousIndex != indexPath {
			self.openGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			self.closeGroup(forCollectionView: collectionView, atIndexPath: previousIndex)
			expandedIndex = indexPath
		}
		
		ds.apply(currentSnapshot, animatingDifferences: true)
	}
	
	private func openGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? ExpandableCell {
			cell.setOpen()
		}
		
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroupData {
			currentSnapshot.insertItems(special.nfts, afterItem: special)
			
		} else if let group = item as? Token {
			currentSnapshot.insertItems(group.nfts ?? [], afterItem: group)
		}
	}
	
	private func closeGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? ExpandableCell {
			cell.setClosed()
		}
		
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroupData {
			currentSnapshot.deleteItems(special.nfts)
			
		} else if let group = item as? Token {
			currentSnapshot.deleteItems(group.nfts ?? [])
		}
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		let item = currentSnapshot.itemIdentifiers(inSection: atIndexPath.section)[0]
		
		if let special = item as? SpecialGroupData {
			return special.nfts[atIndexPath.row-1]
			
		} else if let group = item as? Token {
			return group.nfts?[atIndexPath.row-1]
			
		} else if let i = item as? NFT {
			return i
		}
		
		return nil
	}
	
	func isSectionExpanded(_ section: Int) -> Bool {
		return expandedIndex?.section == section
	}
	
	func searchFor(_ text: String) {
		let numberOfSections = currentSnapshot.numberOfSections
		
		if numberOfSections > 1 {
			currentSnapshot.deleteSections(Array(1..<numberOfSections))
		}
		
		var searchResults: [NFT] = []
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			
			let results = nftGroup.nfts?.filter({ nft in
				return nft.name.range(of: text, options: .caseInsensitive) != nil
			})
			
			if let res = results {
				searchResults.append(contentsOf: res)
			}
		}
		
		currentSnapshot.appendSections([1])
		currentSnapshot.appendItems(searchResults, toSection: 1)
		dataSource?.apply(currentSnapshot, animatingDifferences: true)
	}
	
	func endSearching() {
		
	}
}

extension CollectiblesViewModel: CollectibleListLayoutDelegate {
	
	func data() -> NSDiffableDataSourceSnapshot<SectionEnum, CellDataType> {
		return currentSnapshot
	}
}
	
	
	
	
	
	/*
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var expandedIndex: IndexPath? = nil
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	private var specialGroups: [SpecialGroup] = []
	
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
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let obj = item as? SpecialGroup, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTGroupCell", for: indexPath) as? NFTGroupCell {
				cell.iconView.image = UIImage(named: obj.imageName)
				cell.titleLabel.text = obj.title
				cell.countLabel.text = "\(obj.count)"
				
				return cell
				
			} else if let obj = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTGroupCell", for: indexPath) as? NFTGroupCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				
				if let alias = obj.name {
					cell.titleLabel.text = alias
					cell.titleLabel.lineBreakMode = .byTruncatingTail
				} else {
					cell.titleLabel.text = obj.tokenContractAddress
					cell.titleLabel.lineBreakMode = .byTruncatingMiddle
				}
				
				cell.countLabel.text = "\(obj.nfts?.count ?? 0)"
				
				return cell
				
			} else if let obj = item as? NFT, indexPath.row == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTGroupSingleCell", for: indexPath) as? NFTGroupSingleCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				cell.setup(title: obj.name, subtitle: obj.parentAlias ?? obj.parentContract, balance: obj.balance)
				
				return cell
				
			} else if let obj = item as? NFT, indexPath.row != 0, let cell = tableView.dequeueReusableCell(withIdentifier: "NFTItemCell", for: indexPath) as? NFTItemCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.iconView.frame.size)
				cell.setup(title: obj.name, balance: obj.balance)
				
				if indexPath.section < (self?.specialGroups.count ?? 0) {
					cell.subtitleLabel.text = obj.parentAlias ?? obj.parentContract
				} else {
					cell.subtitleLabel.text = ""
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
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		
		// Build data array of different types
		var topLevelItems: [AnyHashable] = []
		
		if let firstNFT = DependencyManager.shared.balanceService.account.nfts.first?.nfts?.first {
			var duplicateCopy = firstNFT
			
			duplicateCopy.duplicateID = 1
			topLevelItems.append( SpecialGroup(imageName: "star-fill", title: "Favorites", count: 1, nfts: [duplicateCopy]) )
			
			duplicateCopy.duplicateID = 2
			topLevelItems.append( SpecialGroup(imageName: "collectible-group-recents", title: "Recents", count: 1, nfts: [duplicateCopy]) )
			
			duplicateCopy.duplicateID = 3
			topLevelItems.append( SpecialGroup(imageName: "collectible-group-showcase", title: "Showcase", count: 1, nfts: [duplicateCopy]) )
		}
		
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			
			if (nftGroup.nfts ?? []).count > 1 {
				topLevelItems.append( nftGroup )
				
			} else {
				topLevelItems.append( nftGroup.nfts?.first )
			}
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		currentSnapshot.appendSections(Array(0..<(topLevelItems.count) ))
		
		for (index, item) in topLevelItems.enumerated() {
			currentSnapshot.appendItems([item], toSection: index)
		}
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	
	
	// MARK: ViewController Helpers
	
	func shouldOpenCloseForIndexPathTap(_ indexPath: IndexPath) -> Bool {
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[indexPath.row]
		
		if item is SpecialGroup {
			return true
			
		} else if item is Token {
			return true
			
		} else {
			return false
		}
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
		
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroup {
			currentSnapshot.insertItems(special.nfts, afterItem: special)
			
		} else if let group = item as? Token {
			currentSnapshot.insertItems(group.nfts ?? [], afterItem: group)
		}
	}
	
	private func closeGroup(forTableView tableView: UITableView, atIndexPath indexPath: IndexPath) {
		if let cell = tableView.cellForRow(at: indexPath) as? NFTGroupCell {
			cell.setClosed()
		}
		
		let item = currentSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroup {
			currentSnapshot.deleteItems(special.nfts)
			
		} else if let group = item as? Token {
			currentSnapshot.deleteItems(group.nfts ?? [])
		}
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		let item = currentSnapshot.itemIdentifiers(inSection: atIndexPath.section)[0]
		
		if let special = item as? SpecialGroup {
			return special.nfts[atIndexPath.row-1]
			
		} else if let group = item as? Token {
			return group.nfts?[atIndexPath.row-1]
			
		} else if let i = item as? NFT {
			return i
		}
		
		return nil
	}
	
	func isSectionExpanded(_ section: Int) -> Bool {
		return expandedIndex?.section == section
	}
	
	func isLastSpecialGroupSection(_ section: Int) -> Bool {
		return section == specialGroups.count-1
	}
	*/
