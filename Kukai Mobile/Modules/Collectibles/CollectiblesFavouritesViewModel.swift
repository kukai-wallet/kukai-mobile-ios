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
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectiblesCollectionLargeCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionLargeCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
			
			if let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let url = MediaProxyService.displayURL(forNFT: obj)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
				cell.titleLabel.text = obj.name
				cell.subTitleLabel.text = obj.parentAlias ?? ""
				
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
		
		var favs: [NFT] = []
		for token in DependencyManager.shared.balanceService.account.nfts {
			guard !token.isHidden else {
				continue
			}
			
			favs.append(contentsOf: (token.nfts ?? []).filter({ $0.isFavourite && !$0.isHidden }) )
		}
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0])
		normalSnapshot.appendItems(favs, toSection: 0)
		
		ds.apply(normalSnapshot)
		
		// Return success
		self.state = .success(nil)
	}
	
	func nft(forIndexPath indexPath: IndexPath) -> NFT? {
		if let nft = dataSource?.itemIdentifier(for: indexPath) as? NFT {
			return nft
		}
		
		return nil
	}
}