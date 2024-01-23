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
	let isImage: Bool
	let isThumbnail: Bool
	let mediaURL: URL?
	let mediaURL2: URL?
	let width: Double
	let height: Double
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
	private var playerLooper: AVPlayerLooper? = nil
	
	private var sendData = SendContent(enabled: true)
	private var descriptionData = DescriptionContent(description: "")
	
	weak var weakQuantityCell: CollectibleDetailQuantityCell? = nil
	weak var sendDelegate: CollectibleDetailSendDelegate? = nil
	var nft: NFT? = nil
	var isImage = false
	var isFavourited = false
	var isHidden = false
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
		quantityContent = QuantityContent(isOnSale: false, isAudio: false, isInteractableModel: false, isVideo: false, quantity: quantityString(forNFT: nft))
		
		
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
		
		mediaContentForInitialLoad(forNFT: self.nft) { [weak self] response in
			guard let self = self else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to return NFT data"), "Unable to return NFT data")
				return
			}
			
			self.updateQuantityContent(with: response.mediaContent, andOnSale: self.quantityContent.isOnSale)
			
			self.isImage = response.mediaContent.isImage
			section1Content.append(response.mediaContent)
			section1Content.append(self.quantityContent)
			section1Content.append(self.nameContent)
			
			if let creator = objktCollectionData?.creator?.alias {
				section1Content.append(CreatorContent(creatorName: creator))
			}
			
			self.sendData = SendContent(enabled: !(DependencyManager.shared.selectedWalletMetadata?.isWatchOnly ?? false) )
			section1Content.append(self.sendData)
			self.descriptionData = DescriptionContent(description: self.nft?.description ?? "")
			section1Content.append(self.descriptionData)
			self.currentSnapshot.appendItems(section1Content, toSection: 0)
			
			ds.apply(self.currentSnapshot, animatingDifferences: animate) {
				
				// If unbale to determine content type, we need to do a network request to find it
				if response.needsMediaTypeVerification {
					self.mediaContentForFailedOfflineFetch(forNFT: self.nft) { [weak self] mediaContent in
						
						if let newMediaContent = mediaContent {
							self?.replace(existingMediaContent: response.mediaContent, with: newMediaContent)
						} else {
							// Unbale to determine type and unable to locate URL, or fetch packet from URL. Default to missing image palceholder
							let blankMediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: nil, mediaURL2: nil, width: 100, height: 100)
							self?.replace(existingMediaContent: response.mediaContent, with: blankMediaContent)
						}
					}
				}
				
				// If we don't have the full image cached, download it and replace the thumbnail with the real thing
				else if response.needsToDownloadFullImage {
					let newURL = MediaProxyService.url(fromUri: self.nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat())
					let isDualURL = (response.mediaContent.mediaURL2 != nil)
					
					MediaProxyService.cacheImage(url: newURL) { [weak self] size in
						let mediaURL1 = isDualURL ? response.mediaContent.mediaURL : newURL
						let mediaURL2 = isDualURL ? newURL : nil
						let width = Double(size?.width ?? 300)
						let height = Double(size?.height ?? 300)
						let newMediaContent = MediaContent(isImage: response.mediaContent.isImage, isThumbnail: false, mediaURL: mediaURL1, mediaURL2: mediaURL2, width: width, height: height)
						self?.replace(existingMediaContent: response.mediaContent, with: newMediaContent)
					}
				}
			}
			
			self.state = .success(nil)
		}
		
		
		// Load remote data after UI
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
	
	deinit {
		playerController = nil
		playerLooper = nil
	}
	
	
	// MARK: - Data processing
	
	func updateQuantityContent(with mc: MediaContent, andOnSale: Bool) {
		self.quantityContent.isAudio = (mc.mediaURL2 != nil)
		self.quantityContent.isVideo = !mc.isImage
		self.quantityContent.isOnSale = andOnSale
		
		weakQuantityCell?.setup(data: self.quantityContent)
	}
	
	func quantityString(forNFT nft: NFT?) -> String {
		return nft?.balance.description ?? "1"
	}
	
	func mediaContentForInitialLoad(forNFT nft: NFT?, completion: @escaping (( (mediaContent: MediaContent, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
		self.mediaService.getMediaType(fromFormats: nft?.metadata?.formats ?? [], orURL: nil) { [weak self] result in
			let isCached = MediaProxyService.isCached(url: MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat()))
			var mediaType: MediaProxyService.AggregatedMediaType? = nil
			
			if case let .success(returnedMediaType) = result {
				mediaType = MediaProxyService.typesContents(returnedMediaType)
				
			} else if case .failure(_) = result, isCached {
				mediaType = .imageOnly
			}
			
			
			// Can't find data offline, and its not cached already
			if mediaType == nil && !isCached {
				
				// Check to see if we have a cached thumbnail. If so load that (using its dimensions for the correct layout), then load real image later
				let cacheURL = MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: MediaProxyService.Format.medium.rawFormat())
				MediaProxyService.sizeForImageIfCached(url: cacheURL) { size in
					let finalSize = (size ?? CGSize(width: 300, height: 300))
					let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: cacheURL, mediaURL2: nil, width: finalSize.width, height: finalSize.height)
					completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
					return
				}
			}
			
			// if cached, Display full image
			else if mediaType == .imageOnly, isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, loadingThumbnailFirst: false, completion: completion)
				return
			}
			
			// if its an image, but not cached, Load thumbnail, then display image
			else if mediaType == .imageOnly, !isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, loadingThumbnailFirst: true, completion: completion)
				return
			}
			
			// Load video cell straight away
			else if mediaType == .videoOnly {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat()), mediaURL2: nil, width: 0, height: 0)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				return
			}
			
			// if image + audio, and we have the image cached, Load display image and stream audio
			else if mediaType == .imageAndAudio, isCached {
				let imageURL = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat())
				MediaProxyService.sizeForImageIfCached(url: imageURL) { size in
					let finalSize = (size ?? CGSize(width: 300, height: 300))
					let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat()), mediaURL2: imageURL, width: finalSize.width, height: finalSize.height)
					completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
					return
				}
			}
			
			// if image + audio but we don't have the image image cached, Load thumbnail image, then download full image and stream audio
			else if mediaType == .imageAndAudio, !isCached {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat()), mediaURL2: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: MediaProxyService.Format.large.rawFormat()), width: 0, height: 0)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: true, needsMediaTypeVerification: false))
				return
			}
			
			// Fallback
			else {
				let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: MediaProxyService.Format.medium.rawFormat()), mediaURL2: nil, width: 300, height: 300)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
			}
		}
	}
	
	func mediaContentForFailedOfflineFetch(forNFT nft: NFT?, completion: @escaping (( MediaContent? ) -> Void)) {
		let mediaURL = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat()) ?? MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat())
		self.mediaService.getMediaType(fromFormats: nft?.metadata?.formats ?? [], orURL: mediaURL) { result in
			guard let res = try? result.get() else {
				completion(nil)
				return
			}
			
			let mediaType = MediaProxyService.typesContents(res) ?? .imageOnly
			if mediaType == .imageOnly {
				MediaProxyService.cacheImage(url: mediaURL) { size in
					let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: mediaURL, mediaURL2: nil, width: Double(size?.width ?? 300), height: Double(size?.height ?? 300))
					completion(mediaContent)
					return
				}
			} else {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat()), mediaURL2: nil, width: 0, height: 0)
				completion(mediaContent)
				return
			}
		}
	}
	
	func generateImageMediaContent(nft: NFT?,
								   mediaType: MediaProxyService.AggregatedMediaType?,
								   loadingThumbnailFirst: Bool,
								   completion: @escaping (( (mediaContent: MediaContent, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
		
		let cacheURL = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: MediaProxyService.Format.small.rawFormat()) : MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat())
		MediaProxyService.sizeForImageIfCached(url: cacheURL) { size in
			let finalSize = (size ?? CGSize(width: 300, height: 300))
			if mediaType == .imageOnly {
				let url = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI ?? nft?.artifactURI, ofFormat: MediaProxyService.Format.medium.rawFormat()) : MediaProxyService.url(fromUri: nft?.displayURI ?? nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat())
				let mediaContent = MediaContent(isImage: true, isThumbnail: loadingThumbnailFirst, mediaURL: url, mediaURL2: nil, width: finalSize.width, height: finalSize.height)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: loadingThumbnailFirst, needsMediaTypeVerification: false))
				
			} else {
				let url1 = MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: MediaProxyService.Format.large.rawFormat())
				let url2 = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: MediaProxyService.Format.large.rawFormat())
				let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: url1, mediaURL2: url2, width: finalSize.width, height: finalSize.height)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
			}
			
			return
		}
	}
	
	func replace(existingMediaContent oldMediaContent: MediaContent, with newMediaContent: MediaContent) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "error-no-datasource".localized()), "error-no-datasource".localized())
			return
		}
		
		currentSnapshot.insertItems([newMediaContent], beforeItem: oldMediaContent)
		currentSnapshot.deleteItems([oldMediaContent])
		
		DispatchQueue.main.async { [weak self] in
			guard let snapshot = self?.currentSnapshot else {
				return
			}
			
			ds.apply(snapshot, animatingDifferences: true)
		}
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
					
					Logger.app.info("Loading video url: \(url.absoluteString)")
					
					let playerItem = AVPlayerItem(url: url)
					let player = AVQueuePlayer(playerItem: playerItem)
					self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
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
