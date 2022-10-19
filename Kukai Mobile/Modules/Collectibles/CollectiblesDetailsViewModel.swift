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

struct MediaPlaceholder: Hashable {
	let animate: Bool
}

struct MediaContent: Hashable {
	let isImage: Bool
	let mediaURL: URL?
	let height: Double?
}

struct NameContent: Hashable {
	let name: String
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


// MARK: ViewModel

class CollectiblesDetailsViewModel: ViewModel, UICollectionViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	private let mediaService = MediaProxyService()
	private var playerController: AVPlayerViewController? = nil
	private var playerLooper: AVPlayerLooper? = nil
	
	var nft: NFT? = nil
	var placeholderContent = MediaPlaceholder(animate: true)
	var nameContent = NameContent(name: "")
	var attributesContent = AttributesContent(expanded: false)
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, itemIdentifier in
			
			if let obj = itemIdentifier as? TzKTBalanceMetadataAttributeKeyValue, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeItemCell", for: indexPath) as? CollectibleDetailAttributeItemCell {
				cell.keyLabel.text = obj.key
				cell.valueLabel.text = obj.value
				
				return cell
				
			} else if let _ = itemIdentifier as? MediaPlaceholder, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailMediaPlaceholderCell", for: indexPath) as? CollectibleDetailMediaPlaceholderCell {
				cell.activityView.startAnimating()
				return cell
				
			} else if let obj = itemIdentifier as? MediaContent, obj.isImage, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath) as? CollectibleDetailImageCell {
				if let height = obj.height {
					cell.imageViewHeightConstraint.constant = height
				}
				
				MediaProxyService.load(url: obj.mediaURL, to: cell.imageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
				
				return cell
				
			} else if let obj = itemIdentifier as? MediaContent, !obj.isImage, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailVideoCell", for: indexPath) as? CollectibleDetailVideoCell {
				guard let self = self else {
					return cell
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
					cell.setup(avplayerController: pvc)
				}
				
				return cell
				
			} else if let obj = itemIdentifier as? NameContent, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailNameCell", for: indexPath) as? CollectibleDetailNameCell {
				cell.nameLabel.text = obj.name
				
				return cell
				
			} else if let obj = itemIdentifier as? ShowcaseContent, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailShowcaseCell", for: indexPath) as? CollectibleDetailShowcaseCell {
				cell.showcaseLabel.text = "In Showcase (\(obj.count))"
				
				return cell
				
			} else if let obj = itemIdentifier as? SendContent, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailSendCell", for: indexPath) as? CollectibleDetailSendCell {
				cell.sendButton.isEnabled = obj.enabled
				
				return cell
				
			} else if let obj = itemIdentifier as? DescriptionContent, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailDescriptionCell", for: indexPath) as? CollectibleDetailDescriptionCell {
				cell.descriptionLabel.text = obj.description
				
				return cell
				
			} else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeHeaderCell", for: indexPath) as? CollectibleDetailAttributeHeaderCell {
				return cell
			}
			
			return collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath)
		})
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		currentSnapshot.appendSections([0, 1])
		
		var section1Content: [CellDataType] = []
		var section2Content: [CellDataType] = [attributesContent]
		nameContent = NameContent(name: nft?.name ?? "")
		
		// Process section 1
		section1Content.append(placeholderContent)
		section1Content.append(nameContent)
		section1Content.append(ShowcaseContent(count: 1))
		section1Content.append(SendContent(enabled: true))
		section1Content.append(DescriptionContent(description: nft?.description ?? ""))
		currentSnapshot.appendItems(section1Content, toSection: 0)
		
		
		// Process section 2
		if attributesContent.expanded {
			section2Content.append(contentsOf: nft?.metadata?.getKeyValuesFromAttributes() ?? [])
		}
		currentSnapshot.appendItems(section2Content, toSection: 1)
		
		
		// Apply update so placeholder loads
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
		
		
		// Then load the media either form cache, or from internet
		// Sometimes the type of content can be figured out from already cached metadata, in those cases avoid jarring visuals by reloading too quickly, by adding an artifical delay
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			self?.loadDataFromCacheOrDownload(nft: self?.nft)
		}
	}
	
	func loadDataFromCacheOrDownload(nft: NFT?) {
		guard let nft = nft else {
			return
		}
		
		MediaProxyService.sizeForImageIfCached(url: nft.displayURL, fromCache: MediaProxyService.temporaryImageCache()) { [weak self] size in
			guard let self = self else {
				return
			}
			
			if let size = size {
				self.replacePlaceholderWithMedia(isImage: true, height: size.height)
				return
			}
			
			self.mediaService.getMediaType(fromFormats: nft.metadata?.formats ?? [], orURL: nft.displayURL) { result in
				guard let res = try? result.get() else {
					self.state = .failure(result.getFailure(), "Unable to fetch media, due to unknown content type")
					return
				}
				
				if res == .image {
					MediaProxyService.cacheImage(url: nft.displayURL, cache: MediaProxyService.temporaryImageCache()) { size in
						self.replacePlaceholderWithMedia(isImage: true, height: Double(size?.height ?? 300))
					}
				} else {
					self.replacePlaceholderWithMedia(isImage: false, height: 0)
				}
			}
		}
	}
	
	func replacePlaceholderWithMedia(isImage: Bool, height: Double) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		currentSnapshot.insertItems([MediaContent(isImage: isImage, mediaURL: isImage ? nft?.displayURL : nft?.artifactURL, height: height)], beforeItem: nameContent)
		currentSnapshot.deleteItems([placeholderContent])
		
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
		
		ds.apply(currentSnapshot, animatingDifferences: true) { [weak self] in
			if self?.attributesContent.expanded == true {
				collectionView.scrollToItem(at: IndexPath(row: 1, section: 1), at: .bottom, animated: true)
			}
		}
	}
	
	private func openGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? CollectibleDetailAttributeHeaderCell {
			cell.setOpen()
		}
		
		let attributes = nft?.metadata?.getKeyValuesFromAttributes() ?? []
		
		currentSnapshot.insertItems(attributes, afterItem: attributesContent)
		attributesContent.expanded = true
	}
	
	private func closeGroup(forCollectionView collectionView: UICollectionView, atIndexPath indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? CollectibleDetailAttributeHeaderCell {
			cell.setClosed()
		}
		
		let attributes = nft?.metadata?.getKeyValuesFromAttributes() ?? []
		
		currentSnapshot.deleteItems(attributes)
		attributesContent.expanded = false
	}
}
