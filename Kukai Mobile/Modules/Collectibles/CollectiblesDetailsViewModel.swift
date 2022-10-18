//
//  CollectiblesDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift


// MARK: Content objects

struct MediaContent: Hashable {
	let isImage: Bool
	let mediaURL: URL
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
	
	var nft: NFT? = nil
	var attributesContent = AttributesContent(expanded: false)
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	public func makeDataSource(withCollectionView collectionView: UICollectionView) {
		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
			
			if let obj = itemIdentifier as? TzKTBalanceMetadataAttributeKeyValue, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeItemCell", for: indexPath) as? CollectibleDetailAttributeItemCell {
				cell.keyLabel.text = obj.key
				cell.valueLabel.text = obj.value
				
				return cell
				
			} else if let obj = itemIdentifier as? MediaContent, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailImageCell", for: indexPath) as? CollectibleDetailImageCell {
				cell.activityView.startAnimating()
				
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
		
		// TODO: Load a placeholder for media content first, then call `getMediaType`, then load the real thing
		
		let mediaContent = MediaContent(isImage: true, mediaURL: URL(string: "hppts://google.com")!)
		let nameContent = NameContent(name: nft?.name ?? "")
		let showcaseContent = ShowcaseContent(count: 1)
		let sendContent = SendContent(enabled: true)
		let descriptionContent = DescriptionContent(description: nft?.description ?? "")
		currentSnapshot.appendItems([mediaContent, nameContent, showcaseContent, sendContent, descriptionContent], toSection: 0)
		
		var attributeContentArray: [CellDataType] = [attributesContent]
		if attributesContent.expanded {
			attributeContentArray.append(contentsOf: nft?.metadata?.getKeyValuesFromAttributes() ?? [])
		}
		currentSnapshot.appendItems(attributeContentArray, toSection: 1)
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		
		// Return success
		self.state = .success(nil)
	}
	
	public func getMediaType(nft: NFT, completion: @escaping ((Result<MediaProxyService.MediaType, KukaiError>) -> Void)) {
		mediaService.getMediaType(fromFormats: nft.metadata?.formats ?? [], orURL: nft.artifactURL, completion: completion)
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
