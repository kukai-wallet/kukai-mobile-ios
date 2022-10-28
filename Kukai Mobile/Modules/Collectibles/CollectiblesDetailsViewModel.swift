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
	var placeholderContent = MediaPlaceholder(animate: true)
	var nameContent = NameContent(name: "", collectionIcon: nil, collectionName: nil, collectionLink: nil)
	var attributesContent = AttributesContent(expanded: false)
	var attributes: [TzKTBalanceMetadataAttributeKeyValue] = []
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	
	// MARK: - CollectionView Setup
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		collectionView.register(UINib(nibName: "CollectibleDetailOnSaleCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailOnSaleCell")
		collectionView.register(UINib(nibName: "CollectibleDetailMediaPlaceholderCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailMediaPlaceholderCell")
		collectionView.register(UINib(nibName: "CollectibleDetailImageCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailImageCell")
		collectionView.register(UINib(nibName: "CollectibleDetailVideoCell", bundle: nil), forCellWithReuseIdentifier: "CollectibleDetailVideoCell")
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
				
			} else if let item = item as? MediaPlaceholder {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailMediaPlaceholderCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath), withItem: item)
				
			} else if let item = item as? MediaContent, !item.isImage {
				return self.configure(cell: collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailVideoCell", for: indexPath), withItem: item)
				
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
		guard let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		
		// Build snapshot
		currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		currentSnapshot.appendSections([0, 1])
		
		var section1Content: [CellDataType] = []
		
		let nameIcon = DependencyManager.shared.tzktClient.avatarURL(forToken: nft?.parentContract ?? "")
		nameContent = NameContent(name: nft?.name ?? "", collectionIcon: nameIcon, collectionName: nft?.parentAlias ?? nft?.parentContract, collectionLink: nil)
		attributes = nft?.metadata?.getKeyValuesFromAttributes() ?? []
		
		// Process section 1
		section1Content.append(OnSaleData(amount: "15.473 tez"))
		section1Content.append(placeholderContent)
		section1Content.append(nameContent)
		section1Content.append(ShowcaseContent(count: 1))
		section1Content.append(SendContent(enabled: true))
		section1Content.append(DescriptionContent(description: nft?.description ?? ""))
		
		if attributes.count > 0 {
			section1Content.append(attributesContent)
		}
		currentSnapshot.appendItems(section1Content, toSection: 0)
		
		// Process section 2
		reusableAttributeSizingCell = UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeItemCell", ofType: CollectibleDetailAttributeItemCell.self)
		reusableAttributeSizingCell?.keyLabel.text = "a"
		reusableAttributeSizingCell?.valueLabel.text = "b"
		
		
		// Apply update so placeholder loads
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
		
		
		// Then load the media either form cache, or from internet
		// Sometimes the type of content can be figured out from already cached metadata, in those cases avoid jarring visuals by reloading too quickly, by adding an artifical delay
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
			self?.loadDataFromCacheOrDownload(nft: self?.nft)
		}
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
			
		} else if let _ = item as? MediaPlaceholder, let parsedCell = cell as? CollectibleDetailMediaPlaceholderCell {
			parsedCell.activityView.startAnimating()
			return parsedCell
			
		} else if let obj = item as? MediaContent, obj.isImage, let parsedCell = cell as? CollectibleDetailImageCell {
			if let height = obj.height {
				parsedCell.heightConstriant.constant = height
			}
			
			if !layoutOnly {
				MediaProxyService.load(url: obj.mediaURL, to: parsedCell.imageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
			}
			
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
			
		} else if let obj = item as? NameContent, let parsedCell = cell as? CollectibleDetailNameCell {
			parsedCell.nameLabel.text = obj.name
			parsedCell.websiteButton.setTitle(obj.collectionName, for: .normal)
			
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
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.lineSpacing = 6
			paragraphStyle.paragraphSpacing = 6
			
			let attributedtext = NSAttributedString(string: obj.description, attributes: [
				NSAttributedString.Key.foregroundColor: UIColor(named: "text-secondary") ?? UIColor.black,
				NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .light),
				NSAttributedString.Key.paragraphStyle: paragraphStyle
			])
			
			parsedCell.textView.attributedText = attributedtext
			parsedCell.textView.textContainerInset = UIEdgeInsets.zero
			parsedCell.textView.textContainer.lineFragmentPadding = 0
			return parsedCell
			
		} else if let parsedCell = cell as? CollectibleDetailAttributeHeaderCell {
			return parsedCell
		}
		
		return UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
	}
	
	
	
	// MARK: - Data processing
	
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
			
		} else if let item = item as? MediaPlaceholder {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailMediaPlaceholderCell", ofType: CollectibleDetailMediaPlaceholderCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailImageCell", ofType: CollectibleDetailImageCell.self), withItem: item, layoutOnly: true)
			
		} else if let item = item as? MediaContent, !item.isImage {
			return self.configure(cell: UICollectionViewCell.loadFromNib(named: "CollectibleDetailVideoCell", ofType: CollectibleDetailVideoCell.self), withItem: item, layoutOnly: true)
			
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
