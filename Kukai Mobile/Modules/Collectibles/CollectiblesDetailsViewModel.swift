//
//  CollectiblesDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import AVKit
import OSLog


// MARK: Content objects

struct QuantityContent: Hashable {
	var isOnSale: Bool
	var isAudio: Bool
	var isInteractableModel: Bool
	var isVideo: Bool
	let quantity: String
}

struct MediaContent: Hashable {
	let id = UUID()
	let isImage: Bool
	let isThumbnail: Bool
	let mediaURL: URL?
	let mediaURL2: URL?
	let width: Double
	let height: Double
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

struct NameContent: Hashable {
	let name: String
	let collectionIcon: URL?
	let collectionName: String?
	let collectionLink: URL?
}

struct CreatorContent: Hashable {
	let creatorName: String
}

struct SendContent: Hashable {
	let enabled: Bool
}

struct PricesContent: Hashable {
	let lastSalePrice: String
	let floorPrice: String
}

struct DescriptionContent: Hashable {
	let description: String
}

struct AttributesContent: Hashable {
	var expanded: Bool
}

struct AttributeItem: Hashable {
	let name: String
	let value: String
	let percentage: String
}

struct BlankFooter: Hashable {
	let id: Int
}


// MARK: ViewModel

class CollectiblesDetailsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private let mediaService = MediaProxyService()
	private var playerController: AVPlayerViewController? = nil
	private var player: AVPlayer? = nil
	
	private var sendData = SendContent(enabled: true)
	private var descriptionData = DescriptionContent(description: "")
	
	weak var weakQuantityCell: CollectibleDetailQuantityCell? = nil
	weak var sendDelegate: CollectibleDetailSendDelegate? = nil
	var nft: NFT? = nil
	var isFavourited = false
	var isHidden = false
	var mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: nil, mediaURL2: nil, width: 300, height: 300)
	var quantityContent = QuantityContent(isOnSale: false, isAudio: false, isInteractableModel: false, isVideo: false, quantity: "1")
	var nameContent = NameContent(name: "", collectionIcon: nil, collectionName: nil, collectionLink: nil)
	var attributesContent = AttributesContent(expanded: true)
	var attributes: [AttributeItem] = []
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectibleDetailImageCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailImageCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAVCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAVCell")
		collectionView.register(UINib(nibName: "CollectibleDetailQuantityCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailQuantityCell")
		collectionView.register(UINib(nibName: "CollectibleDetailNameCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailNameCell")
		collectionView.register(UINib(nibName: "CollectibleDetailCreatorCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailCreatorCell")
		collectionView.register(UINib(nibName: "CollectibleDetailSendCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailSendCell")
		collectionView.register(UINib(nibName: "CollectibleDetailPricesCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailPricesCell")
		collectionView.register(UINib(nibName: "CollectibleDetailDescriptionCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailDescriptionCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAttributeHeaderCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAttributeHeaderCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAttributeItemCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAttributeItemCell")
		
		// CollectibleDetailQuantityCell
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			guard let self = self else {
				return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath)
			}
			
			if let item = item as? AttributeItem {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeItemCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, !item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAVCell", for: indexPath), withItem: item)
				
			} else if let item = item as? QuantityContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailQuantityCell", for: indexPath), withItem: item)
				
			} else if let item = item as? NameContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailNameCell", for: indexPath), withItem: item)
				
			} else if let item = item as? CreatorContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailCreatorCell", for: indexPath), withItem: item)
				
			} else if let item = item as? SendContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailSendCell", for: indexPath), withItem: item)
				
			} else if let item = item as? PricesContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailPricesCell", for: indexPath), withItem: item)
				
			} else if let item = item as? DescriptionContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailDescriptionCell", for: indexPath), withItem: item)
				
			} else if let item = item as? AttributesContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeHeaderCell", for: indexPath), withItem: item)
				
			} else {
				Logger.app.error("Collectible details unknown type: \(item)")
				return self.configure(cell: nil, withItem: item)
			}
		})
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let nft = nft else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		isFavourited = nft.isFavourite
		isHidden = nft.isHidden
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		currentSnapshot.appendSections([0, 1])
		
		
		var section1Content: [CellDataType] = []
		
		let objktCollectionData = DependencyManager.shared.objktClient.collections[nft.parentContract]
		if let exploreItem = DependencyManager.shared.exploreService.item(forAddress: nft.parentContract) {
			
			let nameIcon = MediaProxyService.url(fromUri: exploreItem.thumbnailImageUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
			nameContent = NameContent(name: nft.name, collectionIcon: nameIcon, collectionName: exploreItem.name, collectionLink: nil)
			
		} else {
			let allPosisbleTokens = DependencyManager.shared.balanceService.account.nfts.filter({ $0.tokenContractAddress == nft.parentContract })
			var tokenObj: Token? = nil
			
			for token in allPosisbleTokens {
				for innerNft in token.nfts ?? [] {
					if nft == innerNft {
						tokenObj = token
						break
					}
				}
			}
			
			let nameIcon = MediaProxyService.url(fromUri: tokenObj?.thumbnailURL, ofFormat: MediaProxyService.Format.icon.rawFormat())
			nameContent = NameContent(name: nft.name, collectionIcon: nameIcon, collectionName: tokenObj?.name ?? tokenObj?.tokenContractAddress?.truncateTezosAddress(), collectionLink: nil)
		}
		
		
		// Parse the NFT's metadata looking for `formats` to find the most relevant media type
		// e.g. An NFT might be primaryily a video, but may also include a small thumbnail image. For this case, we only care about the primary intent
		let types = MediaProxyService.getMediaType(fromFormats: nft.metadata?.formats ?? [])
		let mainType = MediaProxyService.typesContents(types) ?? .imageOnly
		
		if mainType == .imageOnly {
			let smallImage = MediaProxyService.mediumURL(forNFT: nft)
			let largeURL = MediaProxyService.largeURL(forNFT: nft)
			
			Logger.app.info("Small imageURL: \(smallImage?.absoluteString ?? "-")")
			Logger.app.info("Large imageURL: \(largeURL?.absoluteString ?? "-")")
			
			if let imageSize = MediaProxyService.sizeForImageIfCached(url: largeURL) {
				mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: largeURL, mediaURL2: nil, width: imageSize.width, height: imageSize.height)
				
			} else if let imageSize = MediaProxyService.sizeForImageIfCached(url: smallImage) {
				mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: smallImage, mediaURL2: largeURL, width: imageSize.width, height: imageSize.height)
				
			} else {
				mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: largeURL, mediaURL2: nil, width: 300, height: 300)
			}
			
		} else if mainType == .imageAndAudio {
			let imageURL = MediaProxyService.url(fromUri: nft.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat())
			let audioURL =  MediaProxyService.url(fromUri: nft.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat())
			
			Logger.app.info("imageURL: \(imageURL?.absoluteString ?? "-")")
			Logger.app.info("audioURL: \(audioURL?.absoluteString ?? "-")")
			
			mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: audioURL, mediaURL2: imageURL, width: 300, height: 300)
			
		} else {
			let videoURL = MediaProxyService.url(fromUri: nft.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat())
			
			Logger.app.info("videoURL: \(videoURL?.absoluteString ?? "-")")
			
			mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: videoURL, mediaURL2: nil, width: 0, height: 0)
		}
		
		let isAudio =  mainType == .imageAndAudio || mainType == .audioOnly
		let isVideo =  mainType == .videoOnly
		quantityContent = QuantityContent(isOnSale: false, isAudio: isAudio, isInteractableModel: false, isVideo: isVideo, quantity: quantityString(forNFT: nft))
		
		section1Content.append(mediaContent)
		section1Content.append(quantityContent)
		section1Content.append(nameContent)
		
		if let creator = objktCollectionData?.creator?.alias {
			section1Content.append(CreatorContent(creatorName: creator))
		}
		
		self.sendData = SendContent(enabled: !(DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false) )
		section1Content.append(self.sendData)
		self.descriptionData = DescriptionContent(description: self.nft?.description ?? "")
		section1Content.append(self.descriptionData)
		self.currentSnapshot.appendItems(section1Content, toSection: 0)
		
		ds.apply(self.currentSnapshot, animatingDifferences: animate) { [weak self] in
			self?.loadRemoteDataAfterInitialLoad(animate: animate)
		}
		
		self.state = .success(nil)
	}
	
	deinit {
		playerController = nil
		player = nil
	}
	
	
	// MARK: - Data processing
	
	func loadRemoteDataAfterInitialLoad(animate: Bool) {
		guard let nft = nft else {
			return
		}
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		DependencyManager.shared.objktClient.resolveToken(address: nft.parentContract, tokenId: nft.tokenId, forOwnerWalletAddress: address) { [weak self] result in
			guard let self = self, let res = try? result.get(), let data = res.data else {
				return
			}
			
			// On sale
			var needsUpdating = false
			if data.isOnSale() {
				self.quantityContent.isOnSale = true
				self.weakQuantityCell?.setup(data: self.quantityContent)
			}
			
			
			// Last sale and floor price
			let lastSale = data.lastSalePrice()
			let floorPrice = data.floorPrice()
			if lastSale != nil || floorPrice != nil {
				
				let lastSaleString = lastSale == nil ? " " : "\((lastSale ?? .zero()).normalisedRepresentation) XTZ"
				let floorPriceString = floorPrice == nil ? " " : "\((floorPrice ?? .zero()).normalisedRepresentation) XTZ"
				let priceData = PricesContent(lastSalePrice: lastSaleString, floorPrice: floorPriceString)
				self.currentSnapshot.insertItems([priceData], afterItem: self.sendData)
				needsUpdating = true
			}
			
			
			// Attributes
			self.attributes = []
			let totalEditions = data.fa.first?.editions ?? 1
			for attribute in data.token.first?.attributes ?? [] {
				let percentage = ((attribute.attribute.attribute_counts.first?.editions ?? 1) * 100) / totalEditions
				let percentString = percentage.rounded(scale: 2, roundingMode: .bankers).description + "%"
				let attObj = AttributeItem(name: attribute.attribute.name, value: attribute.attribute.value, percentage: percentString)
				self.attributes.append(attObj)
			}
			
			if self.attributes.count > 0 {
				self.currentSnapshot.insertItems([self.attributesContent], afterItem: self.descriptionData)
				self.currentSnapshot.appendItems(self.attributes, toSection: 1)
				needsUpdating = true
			}
			
			
			if needsUpdating {
				self.dataSource?.apply(self.currentSnapshot, animatingDifferences: animate)
			}
		}
	}
	
	func updateQuantityContent(with mc: MediaContent, andOnSale: Bool) {
		self.quantityContent.isAudio = (mc.mediaURL2 != nil)
		self.quantityContent.isVideo = !mc.isImage
		self.quantityContent.isOnSale = andOnSale
		
		weakQuantityCell?.setup(data: self.quantityContent)
	}
	
	func quantityString(forNFT nft: NFT?) -> String {
		return nft?.balance.description ?? "1"
	}
	
	func openOrCloseGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		if attributesContent.expanded == false {
			self.openGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			
		} else if attributesContent.expanded == true {
			self.closeGroup(forCollectionView: collectionView, atIndexPath: indexPath)
		}
		
		ds.apply(self.currentSnapshot, animatingDifferences: true) {
			if self.attributesContent.expanded == true {
				collectionView.scrollToItem(at: IndexPath(row: 0, section: 1), at: .bottom, animated: true)
			}
		}
	}
	
	private func openGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? CollectibleDetailAttributeHeaderCell {
			cell.setOpen()
		}
		
		currentSnapshot.appendItems(attributes, toSection: 1)
		attributesContent.expanded = true
	}
	
	private func closeGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? CollectibleDetailAttributeHeaderCell {
			cell.setClosed()
		}
		
		currentSnapshot.deleteItems(attributes)
		attributesContent.expanded = false
	}
	
	
	
	// MARK: - Generic Cell configuration
	
	func configure(cell: UICollectionViewCell?, withItem item: CellDataType, layoutOnly: Bool = false) -> UICollectionViewCell {
		guard let cell = cell else {
			return UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
		}
		
		if let obj = item as? AttributeItem, let parsedCell = cell as? CollectibleDetailAttributeItemCell {
			parsedCell.keyLabel.text = obj.name
			parsedCell.valueLabel.text = obj.value
			parsedCell.percentLabel.text = obj.percentage
			return parsedCell
			
		} else if let obj = item as? MediaContent, obj.isImage, let parsedCell = cell as? CollectibleDetailImageCell {
			if !parsedCell.setup {
				parsedCell.setup(mediaContent: obj, layoutOnly: layoutOnly)
			}
			
			return parsedCell
			
		} else if let obj = item as? MediaContent, !obj.isImage, let parsedCell = cell as? CollectibleDetailAVCell {

			if !parsedCell.setup, let url = obj.mediaURL, !layoutOnly {
				
				// Make sure we only register the player controller once
				if self.playerController == nil {
					self.playerController = AVPlayerViewController()
					
					// Player looper is the recommended approach, however a video that is less than 1 second caused numerous issues, and an ugly flash while reloading
					// Handling the looping ourselves by listening for the end and then seeking back to start, seems smoother
					// temporarily leaving this here until we get feedback from testers
					//
					//let player = AVQueuePlayer(playerItem: playerItem)
					//self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem1)
					
					let playerItem = AVPlayerItem(url: url)
					self.player = AVPlayer(playerItem: playerItem)
					self.playerController?.player = player
				}
				
				if let pvc = self.playerController {
					let title = self.nft?.name ?? ""
					let artist = self.nft?.parentAlias ?? ""
					let album = self.nft?.parentContract ?? ""
					parsedCell.setup(mediaContent: obj, airPlayName: title, airPlayArtist: artist, airPlayAlbum: album, avplayerController: pvc, layoutOnly: layoutOnly)
				}
			}
			
			return parsedCell
			
		} else if let obj = item as? QuantityContent, let parsedCell = cell as? CollectibleDetailQuantityCell {
			parsedCell.setup(data: obj)
			weakQuantityCell = parsedCell
			return parsedCell
			
		} else if let obj = item as? NameContent, let parsedCell = cell as? CollectibleDetailNameCell {
			parsedCell.nameLabel.text = obj.name
			parsedCell.websiteButton.setTitle(obj.collectionName, for: .normal)
			
			if !layoutOnly {
				MediaProxyService.load(url: obj.collectionIcon, to: parsedCell.websiteImageView, withCacheType: .temporary, fallback: UIImage())
			}
			
			return parsedCell
			
		} else if let obj = item as? CreatorContent, let parsedCell = cell as? CollectibleDetailCreatorCell {
			parsedCell.creatorLabel.text = obj.creatorName
			return parsedCell
			
		} else if let obj = item as? SendContent, let parsedCell = cell as? CollectibleDetailSendCell {
			parsedCell.sendButton.isEnabled = obj.enabled
			parsedCell.setup(delegate: self.sendDelegate)
			
			return parsedCell
			
		} else if let obj = item as? PricesContent, let parsedCell = cell as? CollectibleDetailPricesCell {
			parsedCell.lastSaleLabel.text = obj.lastSalePrice
			parsedCell.floorPriceLabel.text = obj.floorPrice
			return parsedCell
			
		} else if let obj = item as? DescriptionContent, let parsedCell = cell as? CollectibleDetailDescriptionCell {
			parsedCell.setup(withString: obj.description)
			return parsedCell
			
		} else if let parsedCell = cell as? CollectibleDetailAttributeHeaderCell {
			return parsedCell
		}
		
		return UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
	}
}



// MARK: - Custom layout delegate

extension CollectiblesDetailsViewModel: CollectibleDetailLayoutDataDelegate {
	
	func attributeFor(indexPath: IndexPath) -> AttributeItem {
		return attributes[indexPath.row]
	}
	
	func configuredCell(forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
		let identifiers = currentSnapshot.itemIdentifiers(inSection: indexPath.section)
		let item = identifiers[indexPath.row]
		
		if let item = item as? AttributeItem {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeItemCell", ofType: CollectibleDetailAttributeItemCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailImageCell", ofType: CollectibleDetailImageCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, !item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAVCell", ofType: CollectibleDetailAVCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? QuantityContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailQuantityCell", ofType: CollectibleDetailQuantityCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? NameContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailNameCell", ofType: CollectibleDetailNameCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? CreatorContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailCreatorCell", ofType: CollectibleDetailCreatorCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? SendContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailSendCell", ofType: CollectibleDetailSendCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? PricesContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailPricesCell", ofType: CollectibleDetailPricesCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? DescriptionContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailDescriptionCell", ofType: CollectibleDetailDescriptionCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? AttributesContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeHeaderCell", ofType: CollectibleDetailAttributeHeaderCell.self), withItem: item, layoutOnly: true)
			
		} else {
			return self.configure(cell: nil, withItem: item, layoutOnly: true)
		}
	}
}

extension CollectiblesDetailsViewModel {
	
}
