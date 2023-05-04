//
//  CollectionDetailsLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2023.
//

import UIKit
import KukaiCoreSwift

/*
protocol CollectionDetailsLayoutDelegate: AnyObject {
	func data() -> NSDiffableDataSourceSnapshot<Int, AnyHashable>
}

class CollectionDetailsLayout: UICollectionViewLayout {
	
	fileprivate let verticalSpacing: CGFloat = 16
	fileprivate let horizontalSpacing: CGFloat = 18
	
	fileprivate var cache: [[UICollectionViewLayoutAttributes]] = [[]]
	fileprivate var contentHeight: CGFloat = 0
	
	fileprivate var contentWidth: CGFloat {
		guard let collectionView = collectionView else {
			return 0
		}
		let insets = collectionView.contentInset
		return collectionView.bounds.width - (insets.left + insets.right)
	}
	
	public weak var delegate: CollectiblesCollectionLayoutDelegate?
	public var isSearching = false
	
	
	
	override var collectionViewContentSize: CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	
	override func prepare() {
		guard cache[0].count == 0, let data = delegate?.data() else {
			return
		}
		
		createNormalCache(data: data)
	}
	
	/*
	private func prepareSection0(forCollectionView collectionView: UICollectionView, withOffset sectionOffset: CGFloat) -> CGFloat {
		var yOffset = sectionOffset
		
		for cellIndex in 0 ..< collectionView.numberOfItems(inSection: 0) {
			let indexPath = IndexPath(row: cellIndex, section: 0)
			guard let contentView = delegate?.configuredCell(forIndexPath: indexPath).contentView else {
				continue
			}
			
			let requiredSize = contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: 44), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
			let frame = CGRect(x: 0, y: yOffset, width: requiredSize.width, height: requiredSize.height.rounded(.up))
			let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
			attributes.frame = frame
			cache[0].append(attributes)
			
			yOffset += requiredSize.height + cellPadding
		}
		
		return yOffset
	}
	*/
	
	
	private func createNormalCache(data: NSDiffableDataSourceSnapshot<Int, AnyHashable>) {
		var yOffset: CGFloat = 0
		
		let numberOfSections = data.numberOfSections
		for groupIndex in 0..<numberOfSections {
			for (itemIndex, item) in data.itemIdentifiers(inSection: groupIndex).enumerated() {
				var frame = CGRect.zero
				
				if item is CollectionDetailsHeaderObj {
					let indexPath = IndexPath(row: itemIndex, section: groupIndex)
					guard let contentView = delegate?.configuredCell(forIndexPath: indexPath).contentView else {
						continue
					}
					
					/*
					let requiredSize = contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: 44), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
					
					
					
					
					
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectiblesCollectionLayout.controlGroupHeight)
					yOffset += frame.size.height
					yOffset += controlSpacing
					*/
					
				} else if item is NFT {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectiblesCollectionLayout.collectionItemHeight)
					yOffset += frame.size.height
					yOffset += groupSpacing
				}
				
				let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: itemIndex, section: groupIndex))
				attributes.frame = frame
				cache[groupIndex].append(attributes)
			}
			cache.append([])
		}
		
		contentHeight = yOffset
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
		
		// Loop through the cache and look for items in the rect
		for sectionArray in cache {
			for attributes in sectionArray {
				if attributes.frame.intersects(rect) {
					visibleLayoutAttributes.append(attributes)
				}
			}
		}
		
		return visibleLayoutAttributes
	}
	
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		if indexPath.section < cache.count && indexPath.row < cache[indexPath.section].count {
			return cache[indexPath.section][indexPath.row]
		} else {
			return nil
		}
	}
	
	override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
		self.contentHeight = 0
		self.cache = [[]]
		self.prepare()
	}
}
*/
