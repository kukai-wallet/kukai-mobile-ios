//
//  CollectionDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct CollectionDetailsHeaderObj: Hashable {
	let image: UIImage?
	let url: URL?
	let title: String
	let creator: String?
}

class CollectionDetailsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectiblesCollectionHeaderSmallCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionHeaderSmallCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionHeaderMediumCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionHeaderMediumCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionItemLargeWithTextCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
			
			if let obj = item as? CollectionDetailsHeaderObj, obj.creator == nil, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionHeaderSmallCell", for: indexPath) as? CollectiblesCollectionHeaderSmallCell {
				if obj.image != nil {
					cell.iconView.image = obj.image
					
				} else {
					MediaProxyService.load(url: obj.url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				}
				
				cell.titleLabel.text = obj.title
				return cell
				
			} else if let obj = item as? CollectionDetailsHeaderObj, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionHeaderMediumCell", for: indexPath) as? CollectiblesCollectionHeaderMediumCell {
				if obj.image != nil {
					cell.iconView.image = obj.image
					
				} else {
					MediaProxyService.load(url: obj.url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				}
				
				cell.titleLabel.text = obj.title
				cell.creatorLabel.text = obj.creator
				return cell
				
			} else if let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell", for: indexPath) as? CollectiblesCollectionItemLargeWithTextCell {
				let url = MediaProxyService.displayURL(forNFT: obj)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				cell.titleLabel.text = obj.name
				
				return cell
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate datasource"), "Unable to find datasource")
			return
		}
		
		// Build snapshot data
		let title = (externalName ?? selectedToken?.name ?? selectedToken?.tokenContractAddress?.truncateTezosAddress()) ?? ""
		let headerData: [AnyHashable] = [ CollectionDetailsHeaderObj(image: externalImage, url: selectedToken?.thumbnailURL, title: title, creator: nil) ]
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0, 1])
		normalSnapshot.appendItems(headerData, toSection: 0)
		normalSnapshot.appendItems(selectedToken?.nfts ?? [], toSection: 1)
		
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
