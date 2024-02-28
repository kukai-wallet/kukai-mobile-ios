//
//  CollectibleDetailLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/10/2022.
//

import UIKit
import KukaiCoreSwift

protocol CollectibleDetailLayoutDataDelegate: AnyObject {
	func attributeFor(indexPath: IndexPath) -> AttributeItem
	func configuredCell(forIndexPath indexPath: IndexPath) -> UICollectionViewCell
}

class CollectibleDetailLayout: UICollectionViewLayout {
	
	fileprivate var cellPadding: CGFloat = 4
	fileprivate var attributeColumnPadding: CGFloat = 16
	fileprivate var attributeVerticalPadding: CGFloat = 16
	fileprivate var cache: [[UICollectionViewLayoutAttributes]] = [[], []]
	fileprivate var contentHeight: CGFloat = 0
	
	fileprivate var contentWidth: CGFloat {
		guard let collectionView = collectionView else {
			return 0
		}
		let insets = collectionView.contentInset
		return collectionView.bounds.width - (insets.left + insets.right)
	}
	
	fileprivate var numberOfColumns: Int {
		guard let collectionView = collectionView else {
			return 0
		}
		
		return Int(collectionView.bounds.width / 170)
	}
	
	public weak var delegate: CollectibleDetailLayoutDataDelegate?
	
	
	
	override var collectionViewContentSize: CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	
	override func prepare() {
		guard cache[0].count == 0, let collectionView = collectionView else {
			return
		}
		
		contentHeight = prepareSection0(forCollectionView: collectionView, withOffset: contentHeight) // All full width
		contentHeight = prepareSection1(forCollectionView: collectionView, withOffset: contentHeight) // Custom grid pattern
	}
	
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
		
		if collectionView.numberOfItems(inSection: 1) == 0 {
			return yOffset + 25
			
		} else {
			return yOffset
		}
	}
	
	private func prepareSection1(forCollectionView collectionView: UICollectionView, withOffset sectionOffset: CGFloat) -> CGFloat {
		let numberOfCellsInSection = collectionView.numberOfItems(inSection: 1)
		if numberOfCellsInSection == 0 {
			return sectionOffset
		}
		
		var yOffset = sectionOffset
		
		let widthOfCell: CGFloat = (contentWidth - (attributeColumnPadding * CGFloat(numberOfColumns))) / CGFloat(numberOfColumns)
		let heightOfCell: CGFloat = 102
		let reusableSize = CGSize(width: widthOfCell, height: heightOfCell)
		
		var numberOfCells = 0
		var xOffset: CGFloat = 0
		for cellIndex in 0 ..< (numberOfCellsInSection) {
			
			let indexPath = IndexPath(row: cellIndex, section: 1)
			let frame = CGRect(x: xOffset, y: yOffset, width: reusableSize.width, height: reusableSize.height)
			let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
			attributes.frame = frame
			cache[1].append(attributes)
			
			xOffset += (reusableSize.width + attributeColumnPadding)
			numberOfCells += 1
			
			if numberOfCells == numberOfColumns {
				numberOfCells = 0
				xOffset = 0
				yOffset += (heightOfCell + attributeVerticalPadding)
			}
		}
		
		if numberOfCellsInSection % 2 == 0 {
			return (yOffset + 25)
		}
		
		return (yOffset + heightOfCell + 25)
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
		self.cache = [[], []]
		self.prepare()
	}
}
