//
//  CollectiblesFavouritesViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class CollectiblesFavouritesViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var bag = [AnyCancellable]()
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	
	public var isVisible = false
	var forceRefresh = false
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	var imageURLsForCollectibles: [[URL?]] = []
	
	
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
		collectionView.register(UINib(nibName: "CollectiblesCollectionLargeCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionLargeCell")
		collectionView.register(UINib(nibName: "LoadingCollectibleCell", bundle: nil), forCellWithReuseIdentifier: "LoadingCollectibleCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			
			if let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let url = MediaProxyService.displayURL(forNFT: obj, keepGif: true)
				self?.imageURLsForCollectibles.append([url])
				
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let isRichMedia = (type != .imageOnly && type != nil)
				
				cell.setup(title: obj.name, quantity: balance, isRichMedia: isRichMedia)
				
				return cell
				
			} else if let _ = item as? LoadingContainerCellObject, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoadingCollectibleCell", for: indexPath) as? LoadingCollectibleCell {
				cell.setup()
				cell.backgroundColor = .clear
				return cell
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate datasource"), "Unable to find datasource")
			return
		}
		
		var hashableData: [AnyHashable] = []
		
		// If needs shimmers
		let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		let balanceService = DependencyManager.shared.balanceService
		if DependencyManager.shared.balanceService.hasNotBeenFetched(forAddress: selectedAddress), balanceService.isCacheLoadingInProgress() {
			hashableData = [LoadingContainerCellObject(), LoadingContainerCellObject()]
			
		} else {
			for token in DependencyManager.shared.balanceService.account.nfts {
				guard !token.isHidden else {
					continue
				}
				
				hashableData.append(contentsOf: (token.nfts ?? []).filter({ $0.isFavourite && !$0.isHidden }) )
			}
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0])
		normalSnapshot.appendItems(hashableData, toSection: 0)
		
		if forceRefresh {
			ds.applySnapshotUsingReloadData(normalSnapshot)
			forceRefresh = false
		} else {
			ds.apply(normalSnapshot, animatingDifferences: animate)
		}
		
		// Return success
		self.state = .success(nil)
	}
	
	func nft(forIndexPath indexPath: IndexPath) -> NFT? {
		if let nft = dataSource?.itemIdentifier(for: indexPath) as? NFT {
			return nft
		}
		
		return nil
	}
	
	func willDisplayImages(forIndexPath: IndexPath) -> [URL?] {
		return imageURLsForCollectibles[forIndexPath.row]
	}
}
