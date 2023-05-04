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
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var searchSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	private let contractAliases = DependencyManager.shared.environmentService.mainnetEnv.contractAliases
	private let contractAliasesAddressShorthand = DependencyManager.shared.environmentService.mainnetEnv.contractAliases.map({ $0.address[0] })
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	var layout: UICollectionViewLayout = UICollectionViewFlowLayout()
	var isVisible = false
	var isSearching = false
	var sortMenu: MenuViewController? = nil
	
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
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			
			if let sortMenu = item as? MenuViewController, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesSearchCell", for: indexPath) as? CollectiblesSearchCell {
				cell.searchBar.validator = FreeformValidator()
				cell.searchBar.validatorTextFieldDelegate = self?.validatorTextfieldDelegate
				cell.setup(sortMenu: sortMenu)
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
		
		let l = CollectiblesCollectionLayout()
		l.delegate = self
		layout = l
		
		// Build snapshot data
		var hashableData: [AnyHashable] = [sortMenu]
		
		// Add non hidden groups
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			guard !nftGroup.isHidden else {
				continue
			}
			
			hashableData.append(nftGroup)
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0])
		normalSnapshot.appendItems(hashableData, toSection: 0)
		
		ds.apply(normalSnapshot)
		
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
}

extension CollectiblesCollectionsViewModel: CollectiblesCollectionLayoutDelegate {
	
	func data() -> NSDiffableDataSourceSnapshot<SectionEnum, CellDataType> {
		
		if isSearching {
			return searchSnapshot
		}
		
		return normalSnapshot
	}
}
