//
//  CollectibleDetailLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/10/2022.
//

import UIKit
import KukaiCoreSwift

protocol CollectibleDetailLayoutDataDelegate: AnyObject {
	func reusableAttributeCell() -> CollectibleDetailAttributeItemCell?
	func attributeFor(indexPath: IndexPath) -> TzKTBalanceMetadataAttributeKeyValue
	func configuredCell(forIndexPath indexPath: IndexPath) -> UICollectionViewCell
}

class CollectibleDetailLayout: UICollectionViewLayout {
	
	fileprivate var cellPadding: CGFloat = 4
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
		
		return Int(collectionView.bounds.width / minimumCellWidth)
	}
	
	private let minimumCellWidth: CGFloat = 120
	private var defaultAttributeCellHeight: CGFloat = 0
	
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
		
		return yOffset
	}
	
	private func prepareSection1(forCollectionView collectionView: UICollectionView, withOffset sectionOffset: CGFloat) -> CGFloat {
		let numberOfCellsInSection = collectionView.numberOfItems(inSection: 1)
		if numberOfCellsInSection == 0 {
			return sectionOffset
		}
		
		guard let reusableAttributeCell = delegate?.reusableAttributeCell() else {
			return sectionOffset
		}
		
		defaultAttributeCellHeight = reusableAttributeCell.contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: 44), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
		
		var cellSizes: [CGSize] = []
		for cellIndex in 0 ..< (numberOfCellsInSection) {
			let indexPath = IndexPath(row: cellIndex, section: 1)
			guard let attribute = delegate?.attributeFor(indexPath: indexPath) else {
				continue
			}
			
			reusableAttributeCell.keyLabel.text = attribute.key
			reusableAttributeCell.valueLabel.text = attribute.value
			
			let minimumSize = CGSize(width: minimumCellWidth, height: defaultAttributeCellHeight)
			let requiredWidth = reusableAttributeCell.contentView.systemLayoutSizeFitting(minimumSize, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .required).width
			var cellSize: CGSize = minimumSize
			
			
			// if fits into smallest box (taking into account padding for horizontal gap between next cell), record attributes
			if (requiredWidth + cellPadding) <= minimumCellWidth {
				cellSize = CGSize(width: minimumSize.width, height: minimumSize.height)
			}
			
			// if fits into in more than 1 column, but less than max, record as min multiple
			else if (requiredWidth + cellPadding) <= (contentWidth - minimumCellWidth) {
				let multiple = (requiredWidth / minimumCellWidth).rounded(.up)
				cellSize = CGSize(width: minimumCellWidth * multiple, height: minimumSize.height)
			}
			
			// if wider than content width, limit to content width and resize height
			else {
				let newHeight = reusableAttributeCell.contentView.systemLayoutSizeFitting(CGSize(width: contentWidth, height: defaultAttributeCellHeight), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
				cellSize = CGSize(width: contentWidth, height: newHeight)
			}
			
			cellSizes.append(cellSize)
		}
		
		
		// Now that we have calcualted all the sizes, lets group them into rows (as many per row as possible)
		// If we have blank space, expand the items width wise to consume the full space
		var yOffset = sectionOffset
		var startIndex = 0
		var cellIndex = 0
		let maxWidth = minimumCellWidth * CGFloat(numberOfColumns)
		
		repeat {
			var numberOfItems = 0
			var runningTotalWidth: CGFloat = 0
			
			// loop through all cells, until we reach content width
			repeat {
				runningTotalWidth += cellSizes[startIndex+numberOfItems].width
				numberOfItems += 1
				
				if (startIndex + numberOfItems) > cellSizes.count-1 {
					break
				}
			}
			while (runningTotalWidth + (cellSizes[safe: startIndex+numberOfItems]?.width ?? maxWidth)) <= maxWidth
					
			// take all the current sizes, make sure they fit the width
			let nextRow = Array(cellSizes[startIndex..<(numberOfItems + startIndex)])
			let updatedSizes = increase(sizes: nextRow, toConsumeWidth: contentWidth)
					
			// make cache items for them
			var xOffset: CGFloat = 0
			for item in updatedSizes {
				let indexPath = IndexPath(row: cellIndex, section: 1)
				let frame = CGRect(x: xOffset, y: yOffset, width: item.width, height: item.height)
				let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
				attributes.frame = frame
				cache[1].append(attributes)
				
				xOffset = xOffset + item.width + cellPadding
				cellIndex += 1
			}
			
			yOffset += updatedSizes[0].height + cellPadding
			startIndex += numberOfItems
			
		} while startIndex < cellSizes.count
		
		return yOffset
	}
	
	private func increase(sizes: [CGSize], toConsumeWidth: CGFloat) -> [CGSize] {
		
		// If only 1, apply full width
		if sizes.count == 1 {
			var temp = sizes[0]
			temp.width = toConsumeWidth
			
			return [temp]
		}
		
		
		// Check to see if everything is a match already
		let total = sizes.map({ $0.width }).reduce(0, +)
		if total == toConsumeWidth {
			return sizes
		}
		
		
		// If not an exact match, split the remaining space between the elements proportionally
		var tempSizes = sizes
		let toConsumeWidthMinusGaps = (toConsumeWidth - (cellPadding * CGFloat(sizes.count-1)))
		let remainingSpace = (toConsumeWidthMinusGaps - total)
		// If inputs correspond to the correct number of columns, then we divide by columns. Its theres one or more missing columns, we divide by number of inputs so theres no missing piece
		let demoninator = Int(total / minimumCellWidth) == numberOfColumns ? numberOfColumns : sizes.count
		
		for (index, size) in tempSizes.enumerated() {
			let columnsToOccupy = CGFloat(Int(size.width / minimumCellWidth))
			let portion = (remainingSpace * (columnsToOccupy / CGFloat(demoninator)))
			
			tempSizes[index].width += portion
		}
		
		return tempSizes
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
