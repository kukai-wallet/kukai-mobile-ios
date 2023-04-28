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
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	private let contractAliases = DependencyManager.shared.environmentService.mainnetEnv.contractAliases
	private let contractAliasesAddressShorthand = DependencyManager.shared.environmentService.mainnetEnv.contractAliases.map({ $0.address[0] })
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	var layout: UICollectionViewLayout = UICollectionViewFlowLayout()
	var isVisible = false
	var isSearching = false
	var expandedIndex: IndexPath? = nil
	var previousSectionCount = 0
	var sortMenu: MenuViewController? = nil
	var moreMenu: MenuViewController? = nil
	
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
		collectionView.register(UINib(nibName: "GhostnetWarningCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "GhostnetWarningCollectionViewCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			
			if let menu = item as? MenuViewController, let sortMenu = self?.sortMenu, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator()
				cell.searchBar.validatorTextFieldDelegate = self?.validatorTextfieldDelegate
				cell.setup(sortMenu: sortMenu, moreMenu: menu)
				return cell
				
			} else if let obj = item as? SpecialGroupData, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleSpecialGroupCell", for: indexPath) as? CollectibleSpecialGroupCell {
				cell.iconView.image = UIImage(named: obj.imageName) ?? UIImage()
				cell.titleLabel.text = obj.title
				cell.countLabel.text = obj.count.description
				cell.moreButton.isHidden = !obj.isShowcase
				return cell
				
			} else if let obj = item as? Token, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListGroupCell", for: indexPath) as? CollectiblesListGroupCell {
				
				if let index = self?.contractAliasesAddressShorthand.firstIndex(of: obj.tokenContractAddress ?? "") {
					cell.iconView.image = UIImage(named: self?.contractAliases[index].thumbnailUrl ?? "") ?? UIImage()
				} else {
					MediaProxyService.load(url: obj.thumbnailURL, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				}
				
				if let alias = obj.name {
					cell.titleLabel.text = alias
					cell.titleLabel.lineBreakMode = .byTruncatingTail
				} else {
					cell.titleLabel.text = obj.tokenContractAddress?.truncateTezosAddress()
				}
				
				cell.countLabel.text = obj.nfts?.count.description ?? ""
				return cell
				
			} else if let obj = item as? NFT, self?.isSearching == false, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListItemCell", for: indexPath) as? CollectiblesListItemCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				cell.setup(title: obj.name, balance: obj.balance)
				cell.subTitleLabel.text = obj.parentAlias ?? obj.parentContract
				
				return cell
				
			} else if let obj = item as? NFT, self?.isSearching == true, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchResultCell", for: indexPath) as? CollectiblesSearchResultCell {
				let mediaURL = MediaProxyService.thumbnailURL(forNFT: obj)
				MediaProxyService.load(url: mediaURL, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				cell.setup(title: obj.name, balance: obj.balance)
				cell.subTitleLabel.text = obj.parentAlias ?? obj.parentContract
				
				return cell
				
			} else if let _ = item as? GhostnetWarningCellObj {
				return collectionView.dequeueReusableCell(withReuseIdentifier: "GhostnetWarningCollectionViewCell", for: indexPath)
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesListGroupCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate datasource"), "Unable to find datasource")
			return
		}
		
		let l = CollectibleListLayout()
		l.delegate = self
		layout = l
		
		
		// Build special lists list
		var favs: [NFT] = []
		let recents: [NFT] = []
		let showcases: [SpecialGroupData] = []
		
		// Favourites
		for token in DependencyManager.shared.balanceService.account.nfts { // TODO: mark token as hidden if every nft in it is hidden to save time
			guard !token.isHidden else {
				continue
			}
			
			favs.append(contentsOf: (token.nfts ?? []).filter({ $0.isFavourite && !$0.isHidden }) )
		}
		
		// Add duplicate ids to statisfy diffable data source
		for (index, _) in favs.enumerated() {
			favs[index].duplicateID = index+1
		}
		
		
		// Build snapshot data
		var hashableData: [[AnyHashable]] = []
		
		if DependencyManager.shared.currentNetworkType == .testnet {
			hashableData = [[GhostnetWarningCellObj(), moreMenu]]
			
		} else {
			hashableData = [[moreMenu]]
		}
		
		if favs.count > 0 {
			hashableData.append([SpecialGroupData(imageName: "FavoritesOn", title: "Favourites", count: favs.count, isShowcase: false, nfts: favs)])
		}
		
		if recents.count > 0 {
			hashableData.append([SpecialGroupData(imageName: "Timer", title: "Recents", count: 0, isShowcase: false, nfts: [])])
		}
		
		if showcases.count > 0 {
			for showcase in showcases {
				hashableData.append([showcase])
			}
		}
		
		
		// Add non hidden groups
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			guard !nftGroup.isHidden else {
				continue
			}
			
			hashableData.append( [nftGroup] )
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections(Array(0..<(hashableData.count) ))
		
		for (index, item) in hashableData.enumerated() {
			normalSnapshot.appendItems(item, toSection: index)
		}
		
		
		// If refreshing during editing, check if we have the same number of sections at end of last run, if so expand the previously expanded item
		var itemToRefresh: AnyHashable? = nil
		if let eIndex = expandedIndex, normalSnapshot.numberOfSections == previousSectionCount {
			let itemToCheck = hashableData[eIndex.section][0]
			
			if let special = itemToCheck as? SpecialGroupData {
				normalSnapshot.insertItems(special.nfts, afterItem: special)
				itemToRefresh = special.nfts.last
				
			} else if let group = itemToCheck as? Token {
				normalSnapshot.insertItems(group.nfts ?? [], afterItem: group)
				itemToRefresh = group.nfts?.last
			}
			
		} else {
			expandedIndex = nil
		}
		
		
		previousSectionCount = normalSnapshot.numberOfSections
		ds.apply(normalSnapshot, animatingDifferences: animate)
		
		// The last item in each expanded list needs a different gradient, incase the last item is removed, we need to reload that one in order for it to be processed correctly
		if let item = itemToRefresh {
			DispatchQueue.main.async { [weak self] in
				guard let self = self else { return }
				
				self.normalSnapshot.reloadItems([item])
				self.dataSource?.apply(self.normalSnapshot, animatingDifferences: true)
			}
		}
		
		// Return success
		self.state = .success(nil)
	}
	
	
	
	// MARK: UI functions
	
	func shouldOpenCloseForIndexPathTap(_ indexPath: IndexPath) -> Bool {
		var item: AnyHashable = ""
		
		if isSearching {
			item = searchSnapshot.itemIdentifiers(inSection: indexPath.section)[indexPath.row]
		} else {
			item = normalSnapshot.itemIdentifiers(inSection: indexPath.section)[indexPath.row]
		}
		
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
			state = .failure(KukaiError.unknown(withString: "Unable to locate datasource"), "Unable to find datasource")
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
		
		ds.apply(normalSnapshot, animatingDifferences: true)
	}
	
	private func openGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? ExpandableCell {
			cell.setOpen()
		}
		
		let item = normalSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroupData {
			normalSnapshot.insertItems(special.nfts, afterItem: special)
			
		} else if let group = item as? Token {
			normalSnapshot.insertItems(group.nfts ?? [], afterItem: group)
		}
	}
	
	private func closeGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? ExpandableCell {
			cell.setClosed()
		}
		
		let item = normalSnapshot.itemIdentifiers(inSection: indexPath.section)[0]
		
		if let special = item as? SpecialGroupData {
			normalSnapshot.deleteItems(special.nfts)
			
		} else if let group = item as? Token {
			normalSnapshot.deleteItems(group.nfts ?? [])
		}
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		var item: AnyHashable = ""
		
		if isSearching {
			item = searchSnapshot.itemIdentifiers(inSection: atIndexPath.section)[atIndexPath.row]
		} else {
			item = normalSnapshot.itemIdentifiers(inSection: atIndexPath.section)[0]
		}
		
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
		searchSnapshot = normalSnapshot
		let numberOfSections = searchSnapshot.numberOfSections
		
		if numberOfSections > 1 {
			searchSnapshot.deleteSections(Array(1..<numberOfSections))
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
		
		searchSnapshot.appendSections([1])
		searchSnapshot.appendItems(searchResults, toSection: 1)
		dataSource?.apply(searchSnapshot, animatingDifferences: true)
		
	}
	
	func endSearching() {
		searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		dataSource?.apply(normalSnapshot, animatingDifferences: true)
	}
}

extension CollectiblesViewModel: CollectibleListLayoutDelegate {
	
	func data() -> NSDiffableDataSourceSnapshot<SectionEnum, CellDataType> {
		
		if isSearching {
			return searchSnapshot
		}
		
		return normalSnapshot
	}
}
