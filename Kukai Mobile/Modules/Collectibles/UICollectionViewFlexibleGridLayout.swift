//
//  UICollectionViewFlexibleGridLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/10/2022.
//

import UIKit
import OSLog

enum FlexibleGridSectionType {
	case fullWidth
	case grid
}

protocol UICollectionViewFlexibleGridLayoutDelegate: AnyObject {
	func heightForContent(atIndex: IndexPath, withContentWidth: CGFloat, forCollectionView: UICollectionView) -> CGFloat
}

class UICollectionViewFlexibleGridLayout: UICollectionViewLayout {
	
	fileprivate var cellPadding: CGFloat = 6
	fileprivate var cache = [UICollectionViewLayoutAttributes]()
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
		
		return Int(collectionView.bounds.width / 120)
	}
	
	
	
	public var sectionTypes: [FlexibleGridSectionType] = []
	public weak var delegate: UICollectionViewFlexibleGridLayoutDelegate?
	
	
	override var collectionViewContentSize: CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	
	override func prepare() {
		guard cache.isEmpty == true, let collectionView = collectionView else {
			return
		}
		
		let numberOfSections = collectionView.numberOfSections
		if sectionTypes.count != numberOfSections {
			os_log("Invalid number of sectionTypes for collectionView, defaulting to all fullWidth", log: .default, type: .error)
			sectionTypes = Array.init(repeating: .fullWidth, count: numberOfSections)
		}
		
		let columnWidth = contentWidth / CGFloat(numberOfColumns)
		var previousSectionYOffset: CGFloat = 0
		
		for sectionIndex in 0 ..< numberOfSections {
			let currentSectionType = sectionTypes[sectionIndex]
			
			var cellContentWidth: CGFloat = 0
			var xOffset = [CGFloat]()
			var yOffset = [CGFloat]()
			
			if currentSectionType == .grid {
				for column in 0 ..< numberOfColumns {
					xOffset.append(CGFloat(column) * columnWidth)
				}
				yOffset = [CGFloat](repeating: previousSectionYOffset, count: numberOfColumns)
				cellContentWidth = contentWidth / CGFloat(numberOfColumns)
				
			} else {
				xOffset.append(0)
				yOffset.append(previousSectionYOffset)
				cellContentWidth = contentWidth
			}
			
			for cellIndex in 0 ..< collectionView.numberOfItems(inSection: sectionIndex) {
				let indexPath = IndexPath(item: cellIndex, section: sectionIndex)
				let delegateSize = delegate?.heightForContent(atIndex: IndexPath(row: cellIndex, section: sectionIndex), withContentWidth: cellContentWidth, forCollectionView: collectionView) ?? 44
				let height = cellPadding * 2 + delegateSize
				
				var column = 0
				if currentSectionType == .grid {
					let minY = yOffset.min() ?? yOffset[0]
					let index = yOffset.firstIndex(of: minY) ?? 0 // TODO: its not minY we need, it a smallest (yOffset + height)
					
					column = index
				}
				
				let frame = CGRect(x: xOffset[column], y: yOffset[column], width: cellContentWidth, height: height)
				let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
				
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				attributes.frame = insetFrame
				cache.append(attributes)
				
				contentHeight = max(contentHeight, frame.maxY)
				yOffset[column] = yOffset[column] + height
				
				column = column < (numberOfColumns - 1) ? (column + 1) : 0
			}
			
			previousSectionYOffset = yOffset.max() ?? 0
		}
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		
		var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
		
		// Loop through the cache and look for items in the rect
		for attributes in cache {
			if attributes.frame.intersects(rect) {
				visibleLayoutAttributes.append(attributes)
			}
		}
		return visibleLayoutAttributes
	}
	
	override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		if indexPath.item < cache.count {
			return cache[indexPath.item]
		} else {
			return nil
		}
	}
}
