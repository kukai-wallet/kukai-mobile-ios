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
	private var accountDataRefreshedCancellable: AnyCancellable?
	private let contractAliases = DependencyManager.shared.environmentService.mainnetEnv.contractAliases
	private let contractAliasesAddressShorthand = DependencyManager.shared.environmentService.mainnetEnv.contractAliases.map({ $0.address[0] })
	private var previousLayout: LayoutType = .single
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	var isVisible = false
	var isSearching = false
	var sortMenu: MenuViewController? = nil
	var isGroupMode = false
	var itemCount = 0
	var needsLayoutChange = false
	
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
		collectionView.register(UINib(nibName: "CollectiblesCollectionCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionLargeCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionLargeCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionSinglePageCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionSinglePageCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			
			if let sortMenu = item as? MenuViewController, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator()
				cell.searchBar.validatorTextFieldDelegate = self?.validatorTextfieldDelegate
				cell.setup(sortMenu: sortMenu)
				return cell
				
			} else if (self?.itemCount ?? 0) <= 1, let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionSinglePageCell", for: indexPath) as? CollectiblesCollectionSinglePageCell {
				let url = MediaProxyService.displayURL(forNFT: obj)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				cell.titleLabel.text = obj.name
				cell.subTitleLabel.text = obj.parentAlias ?? ""
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				cell.mediaIconView.isHidden = (type == .imageOnly || type == nil)
				
				return cell
				
			} else if self?.isGroupMode == false, let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let url = MediaProxyService.displayURL(forNFT: obj)
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
				
				var totalCount: Int? = nil
				
				if nfts.count > 5 {
					totalCount = nfts.count - 4
				}
				
				let urls = nfts.map({ MediaProxyService.thumbnailURL(forNFT: $0) })
				let title = obj.name ?? obj.tokenContractAddress?.truncateTezosAddress() ?? ""
				
				if let index = self?.contractAliasesAddressShorthand.firstIndex(of: obj.tokenContractAddress ?? "") {
					let image = UIImage(named: self?.contractAliases[index].thumbnailUrl ?? "") ?? UIImage()
					let name = self?.contractAliases[index].name ?? title
					cell.setup(iconImage: image, title: name, imageURLs: urls, totalCount: totalCount)
					
				} else {
					cell.setup(iconUrl: obj.thumbnailURL, title: title, imageURLs: urls, totalCount: totalCount)
				}
				
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
			for nftGroup in DependencyManager.shared.balanceService.account.nfts {
				guard !nftGroup.isHidden else { continue }
				hashableData.append(nftGroup)
			}
			
		} else {
			for nftGroup in DependencyManager.shared.balanceService.account.nfts {
				guard !nftGroup.isHidden else { continue }
				
				let nonHiddenNFTs = nftGroup.nfts?.filter({ !$0.isHidden })
				hashableData.append(contentsOf: nonHiddenNFTs ?? [])
			}
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0, 1])
		normalSnapshot.appendItems([sortMenu], toSection: 0)
		normalSnapshot.appendItems(hashableData, toSection: 1)
		itemCount = hashableData.count
		
		//ds.apply(normalSnapshot)
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
	
	func token(forIndexPath indexPath: IndexPath) -> (token: Token, image: UIImage?, name: String?)? {
		if let t = dataSource?.itemIdentifier(for: indexPath) as? Token {
			if let index = self.contractAliasesAddressShorthand.firstIndex(of: t.tokenContractAddress ?? "") {
				let image = UIImage(named: self.contractAliases[index].thumbnailUrl) ?? UIImage()
				let name = self.contractAliases[index].name
				
				// TODO: remove when we have server
				return (token: t, image: image, name: name)
				
			} else {
				return (token: t, image: nil, name: nil)
			}
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
		switch getLayoutType() {
			case .single:
				return createSingleLayout()
				
			case .column:
				return createColumnLayout()
				
			case .grouped:
				return createGroupLayout()
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
}
