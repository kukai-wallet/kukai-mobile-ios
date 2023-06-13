//
//  CollectiblesRecentsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class CollectiblesRecentsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	
	public var isVisible = false
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && self?.isVisible == true && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}
	}
	
	deinit {
		accountDataRefreshedCancellable?.cancel()
	}
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectiblesCollectionLargeCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionLargeCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
			
			if let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionLargeCell", for: indexPath) as? CollectiblesCollectionLargeCell {
				let url = MediaProxyService.displayURL(forNFT: obj)
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let isRichMedia = (type != .imageOnly && type != nil)
				
				cell.setup(title: obj.name, quantity: balance, isRichMedia: isRichMedia)
				
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
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0])
		normalSnapshot.appendItems(DependencyManager.shared.balanceService.account.recentNFTs, toSection: 0)
		
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
