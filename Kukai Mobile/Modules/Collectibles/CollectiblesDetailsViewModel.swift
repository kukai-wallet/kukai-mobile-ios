//
//  CollectiblesDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import AVKit


// MARK: Content objects

struct OnSaleData: Hashable {
	let amount: String
}

struct MediaContent: Hashable {
	let isImage: Bool
	let isThumbnail: Bool
	let mediaURL: URL?
	let width: Double
	let height: Double
	let quantity: String?
}

struct AudioScrubber: Hashable {
	let audioURL: URL?
}

struct NameContent: Hashable {
	let name: String
	let collectionIcon: URL?
	let collectionName: String?
	let collectionLink: URL?
}

struct ShowcaseContent: Hashable {
	let count: Int
}

struct SendContent: Hashable {
	let enabled: Bool
}

struct DescriptionContent: Hashable {
	let description: String
}

struct AttributesContent: Hashable {
	var expanded: Bool
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
	private var reusableAttributeSizingCell: CollectibleDetailAttributeItemCell? = nil
	
	var nft: NFT? = nil
	var sendTarget: Any? = nil
	var sendAction: Selector? = nil
	var actionsDelegate: CollectibleDetailNameCellDelegate? = nil
	var isImage = false
	var isFavourited = false
	var isHidden = false
	var nameContent = NameContent(name: "", collectionIcon: nil, collectionName: nil, collectionLink: nil)
	var attributesContent = AttributesContent(expanded: false)
	var attributes: [TzKTBalanceMetadataAttributeKeyValue] = []
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectibleDetailOnSaleCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailOnSaleCell")
		collectionView.register(UINib(nibName: "CollectibleDetailImageCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailImageCell")
		collectionView.register(UINib(nibName: "CollectibleDetailVideoCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailVideoCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAudioScrubberCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAudioScrubberCell")
		collectionView.register(UINib(nibName: "CollectibleDetailNameCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailNameCell")
		collectionView.register(UINib(nibName: "CollectibleDetailShowcaseCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailShowcaseCell")
		collectionView.register(UINib(nibName: "CollectibleDetailSendCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailSendCell")
		collectionView.register(UINib(nibName: "CollectibleDetailDescriptionCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailDescriptionCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAttributeHeaderCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAttributeHeaderCell")
		collectionView.register(UINib(nibName: "CollectibleDetailAttributeItemCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAttributeItemCell")
		
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
			guard let self = self else {
				return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath)
			}
			
			if let item = item as? TzKTBalanceMetadataAttributeKeyValue {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeItemCell", for: indexPath), withItem: item)
				
			} else if let item = item as? OnSaleData {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailOnSaleCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, !item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailVideoCell", for: indexPath), withItem: item)
				
			} else if let item = item as? AudioScrubber {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAudioScrubberCell", for: indexPath), withItem: item)
				
			} else if let item = item as? NameContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailNameCell", for: indexPath), withItem: item)
				
			} else if let item = item as? ShowcaseContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailShowcaseCell", for: indexPath), withItem: item)
				
			} else if let item = item as? SendContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailSendCell", for: indexPath), withItem: item)
				
			} else if let item = item as? DescriptionContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailDescriptionCell", for: indexPath), withItem: item)
				
			} else if let item = item as? AttributesContent {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeHeaderCell", for: indexPath), withItem: item)
				
			} else {
				return self.configure(cell: nil, withItem: item)
			}
		})
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let nft = nft else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		reusableAttributeSizingCell = UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeItemCell", ofType: CollectibleDetailAttributeItemCell.self)
		reusableAttributeSizingCell?.keyLabel.text = "a"
		reusableAttributeSizingCell?.valueLabel.text = "b"
		
		isFavourited = TokenStateService.shared.isFavourite(nft: nft)
		isHidden = TokenStateService.shared.isHidden(nft: nft)
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		currentSnapshot.appendSections([0, 1])
		
		
		var section1Content: [CellDataType] = []
		
		let nameIcon = DependencyManager.shared.tzktClient.avatarURL(forToken: nft.parentContract)
		nameContent = NameContent(name: nft.name, collectionIcon: nameIcon, collectionName: nft.parentAlias ?? nft.parentContract, collectionLink: nil)
		attributes = nft.metadata?.getKeyValuesFromAttributes() ?? []
		
		mediaContentForInitialLoad(forNFT: self.nft, quantityString: self.quantityString(forNFT: self.nft)) { [weak self] response in
			guard let self = self else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to return NFT data"), "Unable to return NFT data")
				return
			}
			
			// Process section 0
			self.isImage = response.mediaContent.isImage
			section1Content.append(response.mediaContent)
			
			if let audioScrubber = response.audioScrubber {
				section1Content.append(audioScrubber)
			}
			
			section1Content.append(self.nameContent)
			section1Content.append(ShowcaseContent(count: 1))
			section1Content.append(SendContent(enabled: true))
			section1Content.append(DescriptionContent(description: self.nft?.description ?? ""))
			
			if self.attributes.count > 0 {
				section1Content.append(self.attributesContent)
			}
			
			self.currentSnapshot.appendItems(section1Content, toSection: 0)
			
			ds.apply(self.currentSnapshot, animatingDifferences: animate)
			self.state = .success(nil)
			
			
			// If unbale to determine contentn type, we need to do a network request to find it
			if response.needsMediaTypeVerification {
				self.mediaContentForFailedOfflineFetch(forNFT: self.nft, quantityString: self.quantityString(forNFT: self.nft)) { [weak self] mediaContent in
					
					if let newMediaContent = mediaContent {
						self?.replace(existingMediaContent: response.mediaContent, with: newMediaContent)
					} else {
						self?.state = .failure(KukaiError.unknown(withString: "Unable to determine NFT media type"), "Unable to determine NFT media type")
					}
				}
			}
			
			// If we don't have the full image cached, download it and replace the thumbnail with the real thing
			else if response.needsToDownloadFullImage {
				let mediaURL = MediaProxyService.url(fromUri: self.nft?.displayURI, ofFormat: .small)
				MediaProxyService.cacheImage(url: mediaURL, cache: MediaProxyService.temporaryImageCache()) { [weak self] size in
					let newMediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: mediaURL, width: Double(size?.width ?? 300), height: Double(size?.height ?? 300), quantity: self?.quantityString(forNFT: self?.nft))
					self?.replace(existingMediaContent: response.mediaContent, with: newMediaContent)
				}
			}
		}
		
		ds.apply(self.currentSnapshot, animatingDifferences: animate)
	}
	
	
	// MARK: - Data processing
	
	func quantityString(forNFT nft: NFT?) -> String? {
		var quantity: String? = nil
		if (nft?.balance ?? 0) > 1 {
			quantity = "x\(nft?.balance.description ?? "0")"
		}
		
		return quantity
	}
	
	func mediaContentForInitialLoad(forNFT nft: NFT?, quantityString: String?, completion: @escaping (( (mediaContent: MediaContent, audioScrubber: AudioScrubber?, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
		self.mediaService.getMediaType(fromFormats: nft?.metadata?.formats ?? [], orURL: nil) { [weak self] result in
			
			let isCached = MediaProxyService.isCached(url: MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small), cache: MediaProxyService.temporaryImageCache())
			var mediaType: MediaProxyService.AggregatedMediaType? = nil
			
			if case let .success(returnedMediaType) = result {
				mediaType = MediaProxyService.typesContents(returnedMediaType)
				
			} else if case .failure(_) = result, isCached {
				mediaType = .imageOnly
			}
			
			
			// Can't find data offline, and its not cached already
			if mediaType == nil {
				let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .small), width: 300, height: 300, quantity: quantityString)
				completion((mediaContent: mediaContent, audioScrubber: nil, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
				return
			}
			
			// Display full image
			else if (mediaType == .imageOnly || mediaType == .gifOnly || mediaType == .imageAndAudio), isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, quantity: quantityString, loadingThumbnailFirst: false, completion: completion)
				return
			}
			
			// Load thumbnail, then display image
			else if (mediaType == .imageOnly || mediaType == .gifOnly  || mediaType == .imageAndAudio), !isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, quantity: quantityString, loadingThumbnailFirst: true, completion: completion)
				return
			}
			
			// Load video cell straight away
			else if mediaType == .videoOnly {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), width: 0, height: 0, quantity: quantityString)
				completion((mediaContent: mediaContent, audioScrubber: nil, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				return
			}
			
			// Fallback
			else {
				let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .icon), width: 300, height: 300, quantity: quantityString)
				completion((mediaContent: mediaContent, audioScrubber: nil, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
			}
		}
	}
	
	func mediaContentForFailedOfflineFetch(forNFT nft: NFT?, quantityString: String?, completion: @escaping (( MediaContent? ) -> Void)) {
		let mediaURL = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small) ?? MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw)
		self.mediaService.getMediaType(fromFormats: nft?.metadata?.formats ?? [], orURL: mediaURL) { result in
			guard let res = try? result.get() else {
				completion(nil)
				return
			}
			
			let mediaType = MediaProxyService.typesContents(res) ?? .imageOnly
			if mediaType == .imageOnly {
				MediaProxyService.cacheImage(url: mediaURL, cache: MediaProxyService.temporaryImageCache()) { size in
					let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: mediaURL, width: Double(size?.width ?? 300), height: Double(size?.height ?? 300), quantity: quantityString)
					completion(mediaContent)
					return
				}
			} else if mediaType == .gifOnly {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small), width: 0, height: 0, quantity: quantityString)
				completion(mediaContent)
				return
				
			} else {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), width: 0, height: 0, quantity: quantityString)
				completion(mediaContent)
				return
			}
		}
	}
	
	func generateImageMediaContent(nft: NFT?,
								   mediaType: MediaProxyService.AggregatedMediaType?,
								   quantity: String?,
								   loadingThumbnailFirst: Bool,
								   completion: @escaping (( (mediaContent: MediaContent, audioScrubber: AudioScrubber?, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
		
		let cacheURL = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .small) : MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small)
		MediaProxyService.sizeForImageIfCached(url: cacheURL, fromCache: MediaProxyService.temporaryImageCache()) { size in
			
			let finalSize = (size ?? CGSize(width: 300, height: 300))
			if mediaType == .imageOnly {
				let url = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI ?? nft?.artifactURI, ofFormat: .small) : MediaProxyService.url(fromUri: nft?.displayURI ?? nft?.artifactURI, ofFormat: .small)
				let mediaContent = MediaContent(isImage: true, isThumbnail: loadingThumbnailFirst, mediaURL: url, width: finalSize.width, height: finalSize.height, quantity: quantity)
				completion((mediaContent: mediaContent, audioScrubber: nil, needsToDownloadFullImage: loadingThumbnailFirst, needsMediaTypeVerification: false))
				
			} else if mediaType == .gifOnly {
				let url = MediaProxyService.url(fromUri: nft?.displayURI ?? nft?.artifactURI, ofFormat: .small)
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: url, width: 0, height: 0, quantity: quantity)
				completion((mediaContent: mediaContent, audioScrubber: nil, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				
			} else {
				let url1 = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small)
				let url2 = MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw)
				let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: url1, width: finalSize.width, height: finalSize.height, quantity: quantity)
				let audioScrubber = AudioScrubber(audioURL: url2)
				completion((mediaContent: mediaContent, audioScrubber: audioScrubber, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
			}
			
			return
		}
	}
	
	func replace(existingMediaContent oldMediaContent: MediaContent, with newMediaContent: MediaContent) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		currentSnapshot.insertItems([newMediaContent], beforeItem: nameContent)
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
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
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
		
		if let obj = item as? TzKTBalanceMetadataAttributeKeyValue, let parsedCell = cell as? CollectibleDetailAttributeItemCell {
			parsedCell.keyLabel.text = obj.key
			parsedCell.valueLabel.text = obj.value
			return parsedCell
			
		} else if let item = item as? OnSaleData, let parsedCell = cell as? CollectibleDetailOnSaleCell {
			parsedCell.onSaleAmountLabel.text = item.amount
			return parsedCell
			
		} else if let obj = item as? MediaContent, obj.isImage, let parsedCell = cell as? CollectibleDetailImageCell {
			
			if parsedCell.setup {
				return parsedCell
			}
			
			if obj.isThumbnail {
				parsedCell.activityIndicator.startAnimating()
			} else {
				parsedCell.activityIndicator.isHidden = true
			}
			
			// If landscape image, remove the existing square image constraint and repalce with smaller height aspect ratio image
			if obj.width > obj.height {
				parsedCell.aspectRatioConstraint.isActive = false
				parsedCell.imageView.widthAnchor.constraint(equalTo: parsedCell.imageView.heightAnchor, multiplier: obj.width/obj.height).isActive = true
			}
			
			// If not a landscape image, keep square shape, but adjust the quantity view so that it always appears in bototm left of image, not of the container (as image may be smaller width)
			else {
				parsedCell.layoutIfNeeded()
				
				let newImageWidth = parsedCell.imageView.frame.size.height * (obj.width/obj.height)
				let difference = parsedCell.imageView.frame.size.width - newImageWidth
				
				parsedCell.quantityViewLeadingConstraint.constant += (difference / 2)
			}
			
			
			// Load image if not only perfroming collectionview layout logic
			if !layoutOnly {
				MediaProxyService.load(url: obj.mediaURL, to: parsedCell.imageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
				
				if let quantity = obj.quantity {
					parsedCell.quantityLabel.text = quantity
					
				} else {
					parsedCell.quantityView.isHidden = true
				}
			}
			
			parsedCell.setup = true
			return parsedCell
			
		} else if let obj = item as? MediaContent, !obj.isImage, let parsedCell = cell as? CollectibleDetailVideoCell {
			if layoutOnly {
				return parsedCell
			}
			
			// Make sure we only register the player controller once
			if self.playerController == nil, let url = obj.mediaURL {
				self.playerController = AVPlayerViewController()
				
				let playerItem = AVPlayerItem(url: url)
				let player = AVQueuePlayer(playerItem: playerItem)
				self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
				
				self.playerController?.player = player
				self.playerController?.player?.play()
			}
			
			if let pvc = self.playerController {
				parsedCell.setup(avplayerController: pvc)
			}
			
			return parsedCell
			
		} else if let obj = item as? AudioScrubber, let parsedCell = cell as? CollectibleDetailAudioScrubberCell {
			if layoutOnly {
				return parsedCell
			}
			
			parsedCell.setup(withURL: obj.audioURL)
			return parsedCell
			
		} else if let obj = item as? NameContent, let parsedCell = cell as? CollectibleDetailNameCell {
			parsedCell.nameLabel.text = obj.name
			parsedCell.websiteButton.setTitle(obj.collectionName, for: .normal)
			parsedCell.setup(nft: nft, isImage: isImage, isFavourited: isFavourited, isHidden: isHidden)
			parsedCell.delegate = self.actionsDelegate
			
			if !layoutOnly {
				MediaProxyService.load(url: obj.collectionIcon, to: parsedCell.websiteImageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
			}
			
			return parsedCell
			
		} else if let obj = item as? ShowcaseContent, let parsedCell = cell as? CollectibleDetailShowcaseCell {
			parsedCell.showcaseLabel.text = "In Showcase (\(obj.count))"
			return parsedCell
			
		} else if let obj = item as? SendContent, let parsedCell = cell as? CollectibleDetailSendCell {
			parsedCell.sendButton.isEnabled = obj.enabled
			if let target = sendTarget, let action = sendAction {
				parsedCell.setup(target: target, action: action)
			}
			
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
	
	func reusableAttributeCell() -> CollectibleDetailAttributeItemCell? {
		return reusableAttributeSizingCell
	}
	
	func attributeFor(indexPath: IndexPath) -> TzKTBalanceMetadataAttributeKeyValue {
		return attributes[indexPath.row]
	}
	
	func configuredCell(forIndexPath indexPath: IndexPath) -> UICollectionViewCell {
		let identifiers = currentSnapshot.itemIdentifiers(inSection: indexPath.section)
		let item = identifiers[indexPath.row]
		
		if let item = item as? TzKTBalanceMetadataAttributeKeyValue {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeItemCell", ofType: CollectibleDetailAttributeItemCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? OnSaleData {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailOnSaleCell", ofType: CollectibleDetailOnSaleCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailImageCell", ofType: CollectibleDetailImageCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, !item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailVideoCell", ofType: CollectibleDetailVideoCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? AudioScrubber {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAudioScrubberCell", ofType: CollectibleDetailAudioScrubberCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? NameContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailNameCell", ofType: CollectibleDetailNameCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? ShowcaseContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailShowcaseCell", ofType: CollectibleDetailShowcaseCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? SendContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailSendCell", ofType: CollectibleDetailSendCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? DescriptionContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailDescriptionCell", ofType: CollectibleDetailDescriptionCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? AttributesContent {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeHeaderCell", ofType: CollectibleDetailAttributeHeaderCell.self), withItem: item, layoutOnly: true)
			
		} else {
			return self.configure(cell: nil, withItem: item, layoutOnly: true)
		}
	}
}
