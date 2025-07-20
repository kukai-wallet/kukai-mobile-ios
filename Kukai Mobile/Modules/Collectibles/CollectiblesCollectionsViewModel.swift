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

public struct CollectionEmptyObj: Hashable {
	let id = UUID()
}

class CollectiblesCollectionsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	enum LayoutType {
		case single
		case column
		case grouped
	}
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var bag = [AnyCancellable]()
	private var previousLayout: LayoutType = .single
	
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>?
	var isVisible = false
	var forceRefresh = false
	var isSearching = false
	var sortMenu: MenuViewController? = nil
	var isGroupMode = false
	var itemCount = 0
	var needsLayoutChange = false
	var needsRefreshAfterSearch = false
	
	var imageURLsForCollectionGroups: [URL?] = []
	var imageURLsForCollectibles: [[URL?]] = []
	var nftCollectionRemainderCounts: [Int?] = []
	var displayCount = 2
	
	weak var validatorTextfieldDelegate: ValidatorTextFieldDelegate? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressLoaded
			.dropFirst()
			.sink { [weak self] address in
				if DependencyManager.shared.selectedWalletAddress == address {
					self?.forceRefresh = true
					self?.isSearching = false
					self?.needsLayoutChange = true
					
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
					if self?.isSearching == true {
						self?.needsRefreshAfterSearch = true
					} else {
						self?.refresh(animate: true)
					}
				}
			}.store(in: &bag)
	}
	
	deinit {
		cleanup()
	}
	
	func cleanup() {
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
		collectionView.register(UINib(nibName: "EmptyCollectionCell", bundle: nil), forCellWithReuseIdentifier: "EmptyCollectionCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			guard let self = self else { return UICollectionViewCell() }
			
			if let _ = item.base as? CollectionEmptyObj, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCollectionCell", for: indexPath) as? EmptyCollectionCell {
				return cell
				
			} else if let sortMenu = item.base as? MenuViewController, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator(allowEmpty: true)
				cell.searchBar.validatorTextFieldDelegate = self.validatorTextfieldDelegate
				cell.setup(sortMenu: sortMenu)
				return cell
				
			} else if let obj = item.base as? Int, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultsCountCell", for: indexPath) as? SearchResultsCountCell {
				cell.countLabel.text = "\(obj) Found"
				return cell
				
			} else if let obj = item.base as? String, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCollectionViewCell", for: indexPath) as? MessageCollectionViewCell {
				cell.messageLabel.text = obj
				return cell
				
			} else if self.isSearching, let obj = item.base as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell {
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				cell.setup(title: obj.name, quantity: balance)
				return cell
				
			} else if self.itemCount <= 1, let obj = item.base as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionSinglePageCell", for: indexPath) as? CollectiblesCollectionSinglePageCell {
				cell.titleLabel.text = obj.name
				cell.subTitleLabel.text = obj.parentAlias ?? ""
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				cell.setupViews(quantity: balance, isRichMedia: (type != .imageOnly && type != nil))
				
				return cell
				
			} else if self.isGroupMode == false, let obj = item.base as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let isRichMedia = (type != .imageOnly && type != nil)
				
				cell.setup(title: obj.name, quantity: balance, isRichMedia: isRichMedia)
				
				return cell
				
			} else if let obj = item.base as? Token, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionCell", for: indexPath) as? CollectiblesCollectionCell {
				let title = obj.name ?? obj.tokenContractAddress?.truncateTezosAddress() ?? ""
				cell.setup(title: title, displayCount: displayCount, totalCount: nftCollectionRemainderCounts[indexPath.row] ?? 0)
				
				return cell
			} else if let _ = item.base as? LoadingContainerCellObject, self.isGroupMode, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingGroupModeCell", for: indexPath) as? LoadingGroupModeCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
				
			} else if let _ = item.base as? LoadingContainerCellObject, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingCollectibleCell", for: indexPath) as? LoadingCollectibleCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
			}
			
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionCell", for: indexPath)
		})
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		// Build snapshot data
		let width = min(UIApplication.shared.currentWindowIncludingSuspended?.bounds.width ?? 0, UIApplication.shared.currentWindowIncludingSuspended?.bounds.height ?? 0)
		displayCount = Int((width - 72) / 62) // 62 is width of imageView + 8px padding. 88 is a guess at padding/margin used
		imageURLsForCollectionGroups = []
		imageURLsForCollectibles = []
		nftCollectionRemainderCounts = []
		
		var hashableData: [AnyHashableSendable] = []
		isGroupMode = UserDefaults.standard.bool(forKey: StorageService.settingsKeys.collectiblesGroupModeEnabled)
		
		// Add non hidden groups
		if isGroupMode {
			
			// If needs shimmers
			let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			let balanceService = DependencyManager.shared.balanceService
			if DependencyManager.shared.balanceService.hasBeenFetched(forAddress: selectedAddress), !balanceService.isCacheLoadingInProgress()  {
				for nftGroup in DependencyManager.shared.balanceService.account.nfts {
					guard !nftGroup.isHidden else { continue }
					hashableData.append(.init(nftGroup))
					
					if displayCount <= 0 {
						// fallback for edge case where processing can't find screen
						self.imageURLsForCollectionGroups.append(nil)
						self.imageURLsForCollectibles.append([])
						self.nftCollectionRemainderCounts.append(0)
						
					} else {
						// Process URLs and counts for easier later retreival
						let visibleNfts = nftGroup.nfts?.filter({ !$0.isHidden }) ?? []
						var remainderCount: Int = 0
						
						if visibleNfts.count > displayCount {
							remainderCount = visibleNfts.count - displayCount
						}
						
						let groupURL = MediaProxyService.url(fromUri: nftGroup.thumbnailURL, ofFormat: MediaProxyService.Format.icon.rawFormat())
						self.imageURLsForCollectionGroups.append(groupURL)
						
						let urls = visibleNfts.prefix(displayCount).map({ MediaProxyService.smallURL(forNFT: $0) })
						self.imageURLsForCollectibles.append(urls)
						self.nftCollectionRemainderCounts.append(remainderCount)
					}
				}
			} else {
				hashableData = [.init(LoadingContainerCellObject()), .init(LoadingContainerCellObject()), .init(LoadingContainerCellObject())]
			}
			
		} else {
			
			// If needs shimmers
			let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			if DependencyManager.shared.balanceService.hasNotBeenFetched(forAddress: selectedAddress) {
				hashableData = [.init(LoadingContainerCellObject()), .init(LoadingContainerCellObject())]
			
			} else {
				for nftGroup in DependencyManager.shared.balanceService.account.nfts {
					guard !nftGroup.isHidden else { continue }
					
					let nonHiddenNFTs = nftGroup.nfts?.filter({ !$0.isHidden }).map({ AnyHashableSendable($0) })
					hashableData.append(contentsOf: nonHiddenNFTs ?? [])
				}
			}
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		normalSnapshot.appendSections([0, 1])
		normalSnapshot.appendItems([.init(sortMenu)], toSection: 0)
		
		if hashableData.count > 0 {
			normalSnapshot.appendItems(hashableData, toSection: 1)
		} else {
			normalSnapshot.appendItems([.init(CollectionEmptyObj())], toSection: 1)
		}
		
		itemCount = hashableData.count
		
		ds.applySnapshotUsingReloadData(normalSnapshot)
		
		/*
		if forceRefresh {
			ds.applySnapshotUsingReloadData(normalSnapshot)
			forceRefresh = false
		} else {
			ds.apply(normalSnapshot, animatingDifferences: animate)
		}
		*/
		
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
		if text != "" {
			for nftGroup in DependencyManager.shared.balanceService.account.nfts {
				
				let results = nftGroup.nfts?.filter({ nft in
					return nft.name.range(of: text, options: .caseInsensitive) != nil
				})
				
				if let res = results {
					searchResults.append(contentsOf: res)
				}
			}
			
			if searchResults.count > 0 {
				searchSnapshot.appendSections([2])
				searchSnapshot.appendItems(searchResults.map({ .init($0) }), toSection: 2)
			} else {
				searchSnapshot.appendSections([2])
				searchSnapshot.appendItems([.init("No items found.\n\nYou do not own any matching items.")], toSection: 2)
			}
		}
		
		let countIdentifier = searchSnapshot.itemIdentifiers(inSection: 1)
		searchSnapshot.deleteItems(countIdentifier)
		searchSnapshot.appendItems([.init(searchResults.count)], toSection: 1)
		
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
			
			self.searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
			self.searchSnapshot.appendSections([0, 1])
			self.searchSnapshot.appendItems([.init(self.sortMenu)], toSection: 0)
			self.searchSnapshot.appendItems([.init(0)], toSection: 1)
			
			DispatchQueue.main.async {
				self.dataSource?.apply(self.searchSnapshot, animatingDifferences: true, completion: completion)
			}
		})
	}
	
	/**
	 Same as `startSearching` but in reverse
	 */
	func endSearching(forColelctionView collectionView: UICollectionView, completion: @escaping (() -> Void)) {
		searchSnapshot.deleteSections([1, 2])
		dataSource?.apply(searchSnapshot, animatingDifferences: true, completion: { [weak self] in
			guard let self = self else { return }
			
			DispatchQueue.main.async {
				collectionView.collectionViewLayout = self.layout()
				
				if self.needsRefreshAfterSearch {
					self.refresh(animate: true)
				} else {
					self.dataSource?.apply(self.normalSnapshot, animatingDifferences: true, completion: completion)
				}
			}
		})
	}
	
	func token(forIndexPath indexPath: IndexPath) -> Token? {
		if let t = dataSource?.itemIdentifier(for: indexPath)?.base as? Token {
			return t
		}
		
		return nil
	}
	
	func nft(forIndexPath indexPath: IndexPath) -> NFT? {
		return dataSource?.itemIdentifier(for: indexPath)?.base as? NFT
	}
	
	func willDisplayCollectionImage(forIndexPath: IndexPath) -> URL? {
		
		if forIndexPath.row < imageURLsForCollectionGroups.count {
			let url = imageURLsForCollectionGroups[forIndexPath.row]
			Logger.app.info("willDisplayCollectionImage: \(url?.absoluteString)")
			return url
		}
		
		return nil
	}
	
	func willDisplayImages(forIndexPath: IndexPath) -> [URL?] {
		var urls: [URL?] = []
		
		if isGroupMode && !isSearching {
			if forIndexPath.row < imageURLsForCollectibles.count {
				urls = self.imageURLsForCollectibles[forIndexPath.row]
			} else {
				urls = []
			}
			
		} else if let obj = dataSource?.itemIdentifier(for: forIndexPath)?.base as? NFT {
			urls = [MediaProxyService.mediumURL(forNFT: obj)]
		}
		
		Logger.app.info("willDisplayImages: \(urls)")
		return urls
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
			
			if dataSource?.itemIdentifier(for: IndexPath(row: 0, section: 1))?.base is CollectionEmptyObj {
				return createGroupLayout()
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
