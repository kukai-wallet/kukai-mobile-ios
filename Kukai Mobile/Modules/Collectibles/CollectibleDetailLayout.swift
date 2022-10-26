//
//  CollectibleDetailLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/10/2022.
//

import UIKit
import KukaiCoreSwift

protocol CollectibleDetailLayoutDataDelegate: AnyObject {
	func attributeFor(indexPath: IndexPath) -> TzKTBalanceMetadataAttributeKeyValue
}

class CollectibleDetailLayout: UICollectionViewLayout {
	
	fileprivate var cellPadding: CGFloat = 4
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
		
		return Int(collectionView.bounds.width / minimumCellWidth)
	}
	
	private let minimumCellWidth: CGFloat = 120
	private var defaultAttributeCellHeight: CGFloat = 0
	private var reusableAttributeCell: CollectibleDetailAttributeItemCell? = nil
	
	public weak var delegate: CollectibleDetailLayoutDataDelegate?
	
	
	
	override var collectionViewContentSize: CGSize {
		return CGSize(width: contentWidth, height: contentHeight)
	}
	
	// TODO: check for colelctionView content insets
	// TODO: firgure out inset frame logic without hurting required width
	// TODO: Add in other sections
	
	override func prepare() {
		guard cache.isEmpty == true, let collectionView = collectionView else {
			return
		}
		
		reusableAttributeCell = UICollectionViewCell.loadFromNib(named: "CollectibleDetailAttributeItemCell", ofType: CollectibleDetailAttributeItemCell.self)
		reusableAttributeCell?.keyLabel.text = "a"
		reusableAttributeCell?.valueLabel.text = "b"
		
		guard let reusableAttributeCell = reusableAttributeCell else {
			return
		}
		
		defaultAttributeCellHeight = reusableAttributeCell.contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: 44), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
		print("\n\ndefaultAttributeCellHeight: \(defaultAttributeCellHeight)")
		
		
		var cellSizes: [CGSize] = []
		
		for cellIndex in 0 ..< collectionView.numberOfItems(inSection: 0) {
			guard let attribute = delegate?.attributeFor(indexPath: IndexPath(row: cellIndex, section: 0)) else {
				continue
			}
			
			reusableAttributeCell.keyLabel.text = attribute.key
			reusableAttributeCell.valueLabel.text = attribute.value
			
			let minimumSize = CGSize(width: minimumCellWidth, height: defaultAttributeCellHeight)
			let requiredWidth = reusableAttributeCell.contentView.systemLayoutSizeFitting(minimumSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required).width
			var cellSize: CGSize = minimumSize
			
			print("requiredWidth for index \(cellIndex): \(requiredWidth)")
			
			// if fits into smallest box (taking into account padding for horizontal gap between next cell), record attributes
			if (requiredWidth + cellPadding) <= minimumCellWidth {
				cellSize = CGSize(width: minimumSize.width, height: minimumSize.height)
				print("cellSize is minimum: \(minimumSize)")
			}
			
			// if fits into in more than 1 column, but less than max, record as min multiple
			else if (requiredWidth + cellPadding) <= (contentWidth - minimumCellWidth) {
				let multiple = (requiredWidth / minimumCellWidth).rounded(.up)
				cellSize = CGSize(width: minimumCellWidth * multiple, height: minimumSize.height)
				
				print("cellSize is more than 1, less than all: \(cellSize)")
			}
			
			// if wider than content width, limit to content width and resize height
			else {
				let newHeight = reusableAttributeCell.contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: defaultAttributeCellHeight), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
				cellSize = CGSize(width: contentWidth, height: newHeight)
				
				print("cellSize is more than width, readjusting: \(cellSize)")
			}
			
			print("\n")
			cellSizes.append(cellSize)
		}
		
		print("cellSizes: \(cellSizes)")
		print("\n ===== \n")
		
		
		// Now that we have calcualted all the sizes, lets group them into rows (as many per row as possible)
		// If we have blank space, expand the items width wise to consume the full space
		var yOffset: CGFloat = 0
		var startIndex = 0
		var cellIndex = 0
		let maxWidth = minimumCellWidth * CGFloat(numberOfColumns)
		
		repeat {
			var numberOfItems = 0
			var runningTotalWidth: CGFloat = 0
			
			print("\nStarting with: \(startIndex)")
			
			// loop through all cells, until we reach content width
			repeat {
				runningTotalWidth += cellSizes[startIndex+numberOfItems].width
				print("adding: \(cellSizes[startIndex+numberOfItems].width), fromIndex: \(startIndex+numberOfItems), startIndex: \(startIndex), numberofItems: \(numberOfItems)")
				
				numberOfItems += 1
				if (startIndex + numberOfItems) > cellSizes.count-1 {
					break
				}
				
				print("about to check if \(runningTotalWidth) + \(cellSizes[safe: startIndex+numberOfItems]?.width ?? maxWidth), is less than \(maxWidth)")
			}
			while (runningTotalWidth + (cellSizes[safe: startIndex+numberOfItems]?.width ?? maxWidth)) <= maxWidth
					
			print("reached limit \n")
			
			// take all the current sizes, make sure they fit the width
			let nextRow = Array(cellSizes[startIndex..<(numberOfItems + startIndex)])
			let updatedSizes = increase(sizes: nextRow, toConsumeWidth: contentWidth)
			
			print("updatedSizes: \(updatedSizes) \n")
					
			// make cache items for them
			var xOffset: CGFloat = 0
			for item in updatedSizes {
				let frame = CGRect(x: xOffset, y: yOffset, width: item.width, height: item.height)
				let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: cellIndex, section: 0))
				attributes.frame = frame
				cache.append(attributes)
				
				print("adding frame: \(frame)")
				
				xOffset = xOffset + item.width + cellPadding
				cellIndex += 1
			}
			
			yOffset += updatedSizes[0].height + cellPadding
			startIndex += numberOfItems
			
		} while startIndex < cellSizes.count
		
		print("\n ===== \n")
	}
	
	private func increase(sizes: [CGSize], toConsumeWidth: CGFloat) -> [CGSize] {
		let toConsumeWidthMinusGaps = (toConsumeWidth - (cellPadding * CGFloat(sizes.count-1)))
		let widthPerSize = toConsumeWidthMinusGaps / CGFloat(sizes.count)
		var tempSizes = sizes
		
		for (index, _) in tempSizes.enumerated() {
			tempSizes[index].width = widthPerSize
		}
		
		return tempSizes
	}
	
	private func adjustRectForPadding(rect: CGRect) -> CGRect {
		var tempRect = rect
		var updatedX = tempRect.origin.x
		
		if tempRect.origin.x != 0 {
			updatedX += cellPadding
		}
		
		tempRect = CGRect(x: updatedX, y: tempRect.origin.y + cellPadding, width: tempRect.width, height: tempRect.height)
		
		return tempRect
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
