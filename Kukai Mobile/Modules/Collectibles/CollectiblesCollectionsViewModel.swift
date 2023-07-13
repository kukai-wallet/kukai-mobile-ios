//
//  CollectiblesCollectionsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class CollectiblesCollectionsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	enum LayoutType {
		case single
		case column
		case grouped
	}
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var bag = [AnyCancellable]()
	private var previousLayout: LayoutType = .single
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	var isVisible = false
	var forceRefresh = false
	var isSearching = false
	var sortMenu: MenuViewController? = nil
	var isGroupMode = false
	var itemCount = 0
	var needsLayoutChange = false
	
	weak var validatorTextfieldDelegate: ValidatorTextFieldDelegate? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressLoaded
			.dropFirst()
			.sink { [weak self] address in
				if DependencyManager.shared.selectedWalletAddress == address {
					self?.forceRefresh = true
					
					if self?.isVisible == true {
						self?.refresh(animate: true)
					}
				}
			}.store(in: &bag)
		
		DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && self?.isVisible == true && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectiblesSearchCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesSearchCell")
		collectionView.register(UINib(nibName: "SearchResultCell", bundle: nil), forCellWithReuseIdentifier: "SearchResultCell")
		collectionView.register(UINib(nibName: "SearchResultsCountCell", bundle: nil), forCellWithReuseIdentifier: "SearchResultsCountCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionLargeCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionLargeCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionSinglePageCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionSinglePageCell")
		collectionView.register(UINib(nibName: "LoadingGroupModeCell", bundle: nil), forCellWithReuseIdentifier: "LoadingGroupModeCell")
		collectionView.register(UINib(nibName: "LoadingCollectibleCell", bundle: nil), forCellWithReuseIdentifier: "LoadingCollectibleCell")
		collectionView.register(UINib(nibName: "MessageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MessageCollectionViewCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			guard let self = self else { return UICollectionViewCell() }
			
			if let sortMenu = item as? MenuViewController, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator(allowEmpty: true)
				cell.searchBar.validatorTextFieldDelegate = self.validatorTextfieldDelegate
				cell.setup(sortMenu: sortMenu)
				return cell
				
			} else if let obj = item as? Int, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultsCountCell", for: indexPath) as? SearchResultsCountCell {
				cell.countLabel.text = "\(obj) Found"
				return cell
				
			} else if let obj = item as? String, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCollectionViewCell", for: indexPath) as? MessageCollectionViewCell {
				cell.messageLabel.text = obj
				return cell
				
			} else if self.isSearching, let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell {
				let url = MediaProxyService.displayURL(forNFT: obj, keepGif: true)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				cell.titleLabel.text = obj.name
				return cell
				
			} else if self.itemCount <= 1, let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionSinglePageCell", for: indexPath) as? CollectiblesCollectionSinglePageCell {
				let url = MediaProxyService.displayURL(forNFT: obj, keepGif: true)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				cell.titleLabel.text = obj.name
				cell.subTitleLabel.text = obj.parentAlias ?? ""
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				cell.setupViews(quantity: balance, isRichMedia: (type != .imageOnly && type != nil))
				
				return cell
				
			} else if self.isGroupMode == false, let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let url = MediaProxyService.displayURL(forNFT: obj, keepGif: true)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let isRichMedia = (type != .imageOnly && type != nil)
				
				cell.setup(title: obj.name, quantity: balance, isRichMedia: isRichMedia)
				
				return cell
				
			} else if let obj = item as? Token, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionCell", for: indexPath) as? CollectiblesCollectionCell {
				guard let nfts = obj.nfts else {
					return cell
				}
				
				let visibleNfts = nfts.filter({ !$0.isHidden })
				var totalCount: Int? = nil
				
				if visibleNfts.count > 5 {
					totalCount = nfts.count - 4
				}
				
				let urls = visibleNfts.map({ MediaProxyService.thumbnailURL(forNFT: $0, keepGif: true) })
				let title = obj.name ?? obj.tokenContractAddress?.truncateTezosAddress() ?? ""
				cell.setup(iconUrl: obj.thumbnailURL, title: title, imageURLs: urls, totalCount: totalCount)
				
				return cell
			} else if let _ = item as? LoadingContainerCellObject, self.isGroupMode, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingGroupModeCell", for: indexPath) as? LoadingGroupModeCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
				
			} else if let _ = item as? LoadingContainerCellObject, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingCollectibleCell", for: indexPath) as? LoadingCollectibleCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
			}
			
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate datasource"), "Unable to find datasource")
			return
		}
		
		// Build snapshot data
		var hashableData: [AnyHashable] = []
		isGroupMode = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
		
		// Add non hidden groups
		if isGroupMode {
			
			// If needs shimmers
			let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			if DependencyManager.shared.balanceService.hasNotBeenFetched(forAddress: selectedAddress) {
				hashableData = [LoadingContainerCellObject(), LoadingContainerCellObject(), LoadingContainerCellObject()]
				
			} else {
				for nftGroup in DependencyManager.shared.balanceService.account.nfts {
					guard !nftGroup.isHidden else { continue }
					hashableData.append(nftGroup)
				}
			}
			
		} else {
			
			// If needs shimmers
			let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			if DependencyManager.shared.balanceService.hasNotBeenFetched(forAddress: selectedAddress) {
				hashableData = [LoadingContainerCellObject(), LoadingContainerCellObject()]
			
			} else {
				for nftGroup in DependencyManager.shared.balanceService.account.nfts {
					guard !nftGroup.isHidden else { continue }
					
					let nonHiddenNFTs = nftGroup.nfts?.filter({ !$0.isHidden })
					hashableData.append(contentsOf: nonHiddenNFTs ?? [])
				}
			}
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0, 1])
		normalSnapshot.appendItems([sortMenu], toSection: 0)
		normalSnapshot.appendItems(hashableData, toSection: 1)
		itemCount = hashableData.count
		
		ds.applySnapshotUsingReloadData(normalSnapshot)
		
		let currentLayoutType = getLayoutType()
		if currentLayoutType != previousLayout {
			previousLayout = currentLayoutType
			needsLayoutChange = true
		}
		
		// Return success
		self.state = .success(nil)
	}
	
	
	
	// MARK: UI functions
	
	func searchFor(_ text: String) {
		if searchSnapshot.sectionIdentifiers.count > 2 {
			searchSnapshot.deleteSections([2])
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
		
		let countIdentifier = searchSnapshot.itemIdentifiers(inSection: 1)
		searchSnapshot.deleteItems(countIdentifier)
		searchSnapshot.appendItems([searchResults.count], toSection: 1)
		
		if searchResults.count > 0 {
			searchSnapshot.appendSections([2])
			searchSnapshot.appendItems(searchResults, toSection: 2)
		} else {
			searchSnapshot.appendSections([2])
			searchSnapshot.appendItems(["No items found.\n\nYou do not own any matching items."], toSection: 2)
		}
		
		dataSource?.apply(searchSnapshot, animatingDifferences: true)
	}
	
	/**
	 The searching UI requires a different layout where the first non-search bar item is much smaller than the previous first.
	 Changing the layout and the content at the same time has the unintended side effect of squashing the first item and then sliding it off the screen. This looks ugly
	 Solution is to keep the old layout in place temporarily, clear off all the non search bar items using the same layout, then switch the layout and load the new content. This animates and loads much more smoothly
	 */
	func startSearching(forColelctionView collectionView: UICollectionView, completion: @escaping (() -> Void)) {
		var tempNormal = normalSnapshot
		for i in tempNormal.sectionIdentifiers {
			if i > 0 {
				tempNormal.deleteSections([i])
			}
		}
		
		dataSource?.apply(tempNormal, animatingDifferences: true, completion: { [weak self] in
			guard let self = self else { return }
			
			collectionView.collectionViewLayout = self.layout()
			
			self.searchSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			self.searchSnapshot.appendSections([0, 1])
			self.searchSnapshot.appendItems([self.sortMenu], toSection: 0)
			self.searchSnapshot.appendItems([0], toSection: 1)
			dataSource?.apply(searchSnapshot, animatingDifferences: true, completion: completion)
		})
	}
	
	/**
	 Same as `startSearching` but in reverse
	 */
	func endSearching(forColelctionView collectionView: UICollectionView, completion: @escaping (() -> Void)) {
		searchSnapshot.deleteSections([1, 2])
		dataSource?.apply(searchSnapshot, animatingDifferences: true, completion: { [weak self] in
			guard let self = self else { return }
			
			collectionView.collectionViewLayout = self.layout()
			
			dataSource?.apply(normalSnapshot, animatingDifferences: true, completion: completion)
		})
	}
	
	func token(forIndexPath indexPath: IndexPath) -> Token? {
		if let t = dataSource?.itemIdentifier(for: indexPath) as? Token {
			return t
		}
		
		return nil
	}
	
	func nft(forIndexPath indexPath: IndexPath) -> NFT? {
		return dataSource?.itemIdentifier(for: indexPath) as? NFT
	}
	
	func getLayoutType() -> LayoutType {
		if isGroupMode {
			return .grouped
			
		} else if itemCount <= 1 {
			return .single
			
		} else {
			return .column
		}
	}
	
	func layout() -> UICollectionViewLayout {
		if isSearching {
			return createSearchLayout()
		} else {
			switch getLayoutType() {
				case .single:
					return createSingleLayout()
					
				case .column:
					return createColumnLayout()
					
				case .grouped:
					return createGroupLayout()
			}
		}
	}
	
	private func createSingleLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 4
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	private func createColumnLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(220))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(220))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
				
				group.interItemSpacing = .fixed(18)
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 24
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	private func createGroupLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(104))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(104))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 4
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	private func createSearchLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
				return section
				
			} else if sectionIndex == 1 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(20))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(96))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(96))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
}
