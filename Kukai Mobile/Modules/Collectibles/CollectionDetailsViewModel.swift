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
	let url: URL?
	let title: String
	let creator: String?
}

class CollectionDetailsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var normalSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private var bag = [AnyCancellable]()
	
	var dataSource: UICollectionViewDiffableDataSource<Int, AnyHashable>?
	
	public var isVisible = false
	public var selectedToken: Token? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
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
		collectionView.register(UINib(nibName: "CollectiblesCollectionHeaderSmallCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionHeaderSmallCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionHeaderMediumCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionHeaderMediumCell")
		collectionView.register(UINib(nibName: "CollectiblesCollectionItemLargeWithTextCell", bundle: nil), forCellWithReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
			
			if let obj = item as? CollectionDetailsHeaderObj, obj.creator == nil, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionHeaderSmallCell", for: indexPath) as? CollectiblesCollectionHeaderSmallCell {
				MediaProxyService.load(url: obj.url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				
				cell.titleLabel.text = obj.title
				return cell
				
			} else if let obj = item as? CollectionDetailsHeaderObj, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionHeaderMediumCell", for: indexPath) as? CollectiblesCollectionHeaderMediumCell {
				MediaProxyService.load(url: obj.url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
				
				cell.titleLabel.text = obj.title
				cell.creatorLabel.text = obj.creator
				return cell
				
			} else if let obj = item as? NFT, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell", for: indexPath) as? CollectiblesCollectionItemLargeWithTextCell {
				let url = MediaProxyService.mediumURL(forNFT: obj)
				let halfMegaByte: UInt = 500000
				MediaProxyService.load(url: url, to: cell.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb(), maxAnimatedImageSize: halfMegaByte)
				let balance: String? = obj.balance > 1 ? "x\(obj.balance)" : nil
				
				let types = MediaProxyService.getMediaType(fromFormats: obj.metadata?.formats ?? [])
				let type = MediaProxyService.typesContents(types)
				let isRichMedia = (type != .imageOnly && type != nil)
				
				cell.setup(title: obj.name, quantity: balance, isRichMedia: isRichMedia)
				
				return cell
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectiblesCollectionItemLargeWithTextCell", for: indexPath)
		})
	}
	
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		var tokenToView = selectedToken
		if let updatedSelectedToken = DependencyManager.shared.balanceService.account.nfts.first(where: { $0.tokenContractAddress == selectedToken?.tokenContractAddress && $0.tokenId == selectedToken?.tokenId && $0.name == selectedToken?.name}) {
			tokenToView = updatedSelectedToken
		}
		
		
		// Build snapshot
		normalSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		normalSnapshot.appendSections([0, 1])
		
		
		// Build snapshot data
		let title = (tokenToView?.name ?? tokenToView?.tokenContractAddress?.truncateTezosAddress()) ?? ""
		let url = MediaProxyService.url(fromUri: tokenToView?.thumbnailURL, ofFormat: MediaProxyService.Format.small.rawFormat())
		
		if let creator = DependencyManager.shared.objktClient.collections[tokenToView?.tokenContractAddress ?? ""]?.creator?.alias {
			normalSnapshot.appendItems([ CollectionDetailsHeaderObj(url: url, title: title, creator: creator) ], toSection: 0)
			
		} else {
			normalSnapshot.appendItems([ CollectionDetailsHeaderObj(url: url, title: title, creator: nil) ], toSection: 0)
		}
		
		let visibleNfts = (tokenToView?.nfts ?? []).filter({ !$0.isHidden })
		normalSnapshot.appendItems(visibleNfts, toSection: 1)
		ds.applySnapshotUsingReloadData(normalSnapshot)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	func nft(forIndexPath indexPath: IndexPath) -> NFT? {
		if let nft = dataSource?.itemIdentifier(for: indexPath) as? NFT {
			return nft
		}
		
		return nil
	}
	
	func menuViewControllerForMoreButton(forViewController: UIViewController) -> MenuViewController? {
		var actions: [[UIAction]] = []
		let contractAddress = selectedToken?.tokenContractAddress ?? ""
		
		if let objktCollectionInfo = DependencyManager.shared.objktClient.collections[contractAddress] {
			
			// Social section
			if let twitterURL = objktCollectionInfo.twitterURL() {
				var updatedTwitterURL = twitterURL
				if contractAddress == "KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton" && selectedToken?.mintingTool == "https://teia.art/mint" {
					updatedTwitterURL = URL(string: "https://twitter.com/TeiaArt")!
				}
				
				let action = UIAction(title: "Twitter", image: UIImage(named: "Social_Twitter_1color")) { action in
					
					let path = updatedTwitterURL.path()
					let pathIndex = path.index(after: path.startIndex)
					let twitterUsername = path.suffix(from: pathIndex)
					if let deeplinkURL = URL(string: "twitter://user?screen_name=\(twitterUsername)"), UIApplication.shared.canOpenURL(deeplinkURL) {
						UIApplication.shared.open(deeplinkURL)
					} else {
						UIApplication.shared.open(updatedTwitterURL)
					}
				}
				
				actions.append([action])
			}
			
			
			// Web section
			var webActions: [UIAction] = []
			
			
			let action = UIAction(title: "View Marketplace", image: UIImage(named: "ArrowWeb")) { action in
				if let url = URL(string: "https://objkt.com/collection/\(contractAddress)") {
					UIApplication.shared.open(url)
				}
			}
			webActions.append(action)
			
			if let websiteURL = objktCollectionInfo.websiteURL() {
				let action = UIAction(title: "Collection Website", image: UIImage(named: "ArrowWeb")) { action in
					UIApplication.shared.open(websiteURL)
				}
				
				webActions.append(action)
			}
			
			actions.append(webActions)
			return MenuViewController(actions: actions, header: nil, alertStyleIndexes: nil, sourceViewController: forViewController)
		}
		
		return nil
	}
}
