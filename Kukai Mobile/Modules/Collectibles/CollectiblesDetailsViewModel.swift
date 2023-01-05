//
//  CollectiblesDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import AVKit
import MediaPlayer


// MARK: Content objects

struct OnSaleData: Hashable {
	let amount: String
}

struct MediaContent: Hashable {
	let isImage: Bool
	let isThumbnail: Bool
	let mediaURL: URL?
	let mediaURL2: URL?
	let width: Double
	let height: Double
	let quantity: String?
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
	private var reusableAttributeSizingCell: CollectibleDetailAttributeItemCell? = nil
	private var avPlayer: AVPlayer? = nil
	/*
	 private var playerController: AVPlayerViewController? = nil
	 private var playerControllerBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
	 private var playerLooper: AVPlayerLooper? = nil
	 */
	
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
		collectionView.register(UINib(nibName: "CollectibleDetailAVCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailAVCell")
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
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAVCell", for: indexPath), withItem: item)
				
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
			
			self.isImage = response.mediaContent.isImage
			section1Content.append(response.mediaContent)
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
				let newURL = MediaProxyService.url(fromUri: self.nft?.displayURI, ofFormat: .small)
				let isDualURL = (response.mediaContent.mediaURL2 != nil)
				
				MediaProxyService.cacheImage(url: newURL, cache: MediaProxyService.temporaryImageCache()) { [weak self] size in
					let mediaURL1 = isDualURL ? response.mediaContent.mediaURL : newURL
					let mediaURL2 = isDualURL ? newURL : nil
					let width = Double(size?.width ?? 300)
					let height = Double(size?.height ?? 300)
					let newMediaContent = MediaContent(isImage: response.mediaContent.isImage, isThumbnail: false, mediaURL: mediaURL1, mediaURL2: mediaURL2, width: width, height: height, quantity: self?.quantityString(forNFT: self?.nft))
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
	
	func mediaContentForInitialLoad(forNFT nft: NFT?, quantityString: String?, completion: @escaping (( (mediaContent: MediaContent, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
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
				let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .small), mediaURL2: nil, width: 300, height: 300, quantity: quantityString)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
				return
			}
			
			// if cached, Display full image
			else if (mediaType == .imageOnly || mediaType == .gifOnly), isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, quantity: quantityString, loadingThumbnailFirst: false, completion: completion)
				return
			}
			
			// if its an image, but not cached, Load thumbnail, then display image
			else if (mediaType == .imageOnly || mediaType == .gifOnly), !isCached {
				self?.generateImageMediaContent(nft: self?.nft, mediaType: mediaType, quantity: quantityString, loadingThumbnailFirst: true, completion: completion)
				return
			}
			
			// Load video cell straight away
			else if mediaType == .videoOnly {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), mediaURL2: nil, width: 0, height: 0, quantity: quantityString)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				return
			}
			
			// if image + audio, and we have the image cached, Load display image and stream audio
			else if mediaType == .imageAndAudio, isCached {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), mediaURL2: MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small), width: 0, height: 0, quantity: quantityString)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				return
			}
			
			// if image + audio but we don't have the image image cached, Load thumbnail image, then download full image and stream audio
			else if mediaType == .imageAndAudio, !isCached {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), mediaURL2: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .small), width: 0, height: 0, quantity: quantityString)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: true, needsMediaTypeVerification: false))
				return
			}
			
			// Fallback
			else {
				let mediaContent = MediaContent(isImage: true, isThumbnail: true, mediaURL: MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .icon), mediaURL2: nil, width: 300, height: 300, quantity: quantityString)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: true))
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
					let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: mediaURL, mediaURL2: nil, width: Double(size?.width ?? 300), height: Double(size?.height ?? 300), quantity: quantityString)
					completion(mediaContent)
					return
				}
			} else if mediaType == .gifOnly {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small), mediaURL2: nil, width: 0, height: 0, quantity: quantityString)
				completion(mediaContent)
				return
				
			} else {
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw), mediaURL2: nil, width: 0, height: 0, quantity: quantityString)
				completion(mediaContent)
				return
			}
		}
	}
	
	func generateImageMediaContent(nft: NFT?,
								   mediaType: MediaProxyService.AggregatedMediaType?,
								   quantity: String?,
								   loadingThumbnailFirst: Bool,
								   completion: @escaping (( (mediaContent: MediaContent, needsToDownloadFullImage: Bool, needsMediaTypeVerification: Bool) ) -> Void)) {
		
		let cacheURL = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI, ofFormat: .small) : MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small)
		MediaProxyService.sizeForImageIfCached(url: cacheURL, fromCache: MediaProxyService.temporaryImageCache()) { size in
			
			let finalSize = (size ?? CGSize(width: 300, height: 300))
			if mediaType == .imageOnly {
				let url = loadingThumbnailFirst ? MediaProxyService.url(fromUri: nft?.thumbnailURI ?? nft?.artifactURI, ofFormat: .small) : MediaProxyService.url(fromUri: nft?.displayURI ?? nft?.artifactURI, ofFormat: .small)
				let mediaContent = MediaContent(isImage: true, isThumbnail: loadingThumbnailFirst, mediaURL: url, mediaURL2: nil, width: finalSize.width, height: finalSize.height, quantity: quantity)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: loadingThumbnailFirst, needsMediaTypeVerification: false))
				
			} else if mediaType == .gifOnly {
				let url = MediaProxyService.url(fromUri: nft?.displayURI ?? nft?.artifactURI, ofFormat: .small)
				let mediaContent = MediaContent(isImage: false, isThumbnail: false, mediaURL: url, mediaURL2: nil, width: 0, height: 0, quantity: quantity)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
				
			} else {
				let url1 = MediaProxyService.url(fromUri: nft?.artifactURI, ofFormat: .raw)
				let url2 = MediaProxyService.url(fromUri: nft?.displayURI, ofFormat: .small)
				let mediaContent = MediaContent(isImage: true, isThumbnail: false, mediaURL: url1, mediaURL2: url2, width: finalSize.width, height: finalSize.height, quantity: quantity)
				completion((mediaContent: mediaContent, needsToDownloadFullImage: false, needsMediaTypeVerification: false))
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
			if !parsedCell.setup {
				parsedCell.setup(mediaContent: obj, layoutOnly: layoutOnly)
			}
			
			return parsedCell
			
		} else if let obj = item as? MediaContent, !obj.isImage, let parsedCell = cell as? CollectibleDetailAVCell {
			if !parsedCell.setup, let url = obj.mediaURL {
				let player = AVPlayer(url: url)
				self.avPlayer = player
				//parsedCell.setup(mediaContent: obj, avPlayer: player)
			}
			
			return parsedCell
			
			
			
			/*
			if layoutOnly {
				return parsedCell
			}
			
			// Make sure we only register the player controller once
			if self.playerController == nil, let url = obj.mediaURL {
				
				self.playerController = AVPlayerViewController()
				
				
				/*
				MediaProxyService.cacheImage(url: obj.mediaURL2, cache: MediaProxyService.temporaryImageCache()) { size in
					print("cached")
				}
				*/
				
				MediaProxyService.temporaryImageCache().retrieveImage(forKey: obj.mediaURL2?.absoluteString ?? "", options: []) { result in
					guard let res = try? result.get() else {
						print("Didn't have image cached")
						return
					}
					
					print("Did have image cached")
					
					self.playerControllerBackground.image = res.image
					self.playerController?.contentOverlayView?.addSubview(self.playerControllerBackground)
					
					if let overlay = self.playerController?.contentOverlayView {
						self.playerControllerBackground.translatesAutoresizingMaskIntoConstraints = false
						NSLayoutConstraint.activate([
							self.playerControllerBackground.leadingAnchor.constraint(equalTo: overlay.leadingAnchor),
							self.playerControllerBackground.trailingAnchor.constraint(equalTo: overlay.trailingAnchor),
							self.playerControllerBackground.topAnchor.constraint(equalTo: overlay.topAnchor),
							self.playerControllerBackground.bottomAnchor.constraint(equalTo: overlay.bottomAnchor)
						])
					}
					
					let playerItem = AVPlayerItem(url: url)
					
					let title = AVMutableMetadataItem()
					title.identifier = .commonIdentifierTitle
					title.value = (self.nft?.name ?? "123") as NSString
					title.extendedLanguageTag = "und"
					
					let artist = AVMutableMetadataItem()
					artist.identifier = .commonIdentifierArtist
					artist.value = (self.nft?.parentAlias ?? "456") as NSString
					artist.extendedLanguageTag = "und"
					
					let artwork = AVMutableMetadataItem()
					artwork.identifier = .commonIdentifierArtwork
					artwork.value = (self.playerControllerBackground.image?.jpegData(compressionQuality: 1) ?? Data()) as NSData
					artwork.dataType = kCMMetadataBaseDataType_JPEG as String
					artwork.extendedLanguageTag = "und"
					
					playerItem.externalMetadata = [title, artist, artwork]
					
					//self.playerController?.updatesNowPlayingInfoCenter = false
					
					
					let player = AVQueuePlayer(playerItem: playerItem)
					
					
					/*
					let artwork2 = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
						print("Inside MPMediaItemArtwork request")
						return res.image ?? UIImage.unknownToken()
					}
					
					let mpNowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
					mpNowPlayingInfoCenter.nowPlayingInfo = [
						MPMediaItemPropertyTitle: "Video Name",
						MPMediaItemPropertyArtist: "Artist Name",
						MPMediaItemPropertyAlbumTitle: "Album Title",
						MPMediaItemPropertyArtwork: artwork2,
						MPMediaItemPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue, // can also be audio
						MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0, // just starting
						MPNowPlayingInfoPropertyPlaybackRate: 1.0, // this indicates the playing speed
					]
					*/
					
					player.allowsExternalPlayback = false
					
					
					let audioSession = AVAudioSession.sharedInstance()
					if let sessionResult = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
						print("details set on shared instance: \(sessionResult)")
						
						UIApplication.shared.beginReceivingRemoteControlEvents()
						let commandCenter = MPRemoteCommandCenter.shared()
						
						commandCenter.playCommand.isEnabled = true
						commandCenter.pauseCommand.isEnabled = true
						
						commandCenter.playCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
							print("inside remote player play command")
							player.play()
							return MPRemoteCommandHandlerStatus.success
						}
						
						commandCenter.pauseCommand.addTarget { [self] (commandEvent) -> MPRemoteCommandHandlerStatus in
							print("inside remote player pause command")
							player.pause()
							return MPRemoteCommandHandlerStatus.success
						}
						
					}
					
					
					
					
					/*
					let audioSession = AVAudioSession.sharedInstance()
					if let sessionResult = try? audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio) {
						print("details set on shared instance: \(sessionResult)")
						
						let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { size in
							print("Inside MPMediaItemArtwork request")
							return res.image ?? UIImage.unknownToken()
						}
						
						//self.playerController?.updatesNowPlayingInfoCenter = true
						//self.playerController?.player?.currentItem?.nowPlayingInfo = [MPMediaItemPropertyTitle: self.nft?.name ?? "123", MPMediaItemPropertyArtist: self.nft?.parentAlias ?? "456", MPMediaItemPropertyArtwork: artwork]
						
						//MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: self.nft?.name ?? "123", MPMediaItemPropertyArtist: self.nft?.parentAlias ?? "456", MPMediaItemPropertyArtwork: artwork]
					} else {
						print("unable to set shared session details")
					}
					*/
					
					self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
					self.playerController?.player = player
					self.playerController?.player?.play()
					
				}
			}
			
			if let pvc = self.playerController {
				parsedCell.setup(avplayerController: pvc)
			}
			
			return parsedCell
			*/
			
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
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailAVCell", ofType: CollectibleDetailAVCell.self), withItem: item, layoutOnly: true)
			
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
