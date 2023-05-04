//
//  CollectiblesCollectionLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift

protocol CollectiblesCollectionLayoutDelegate: AnyObject {
	func data() -> NSDiffableDataSourceSnapshot<Int, AnyHashable>
}

class CollectiblesCollectionLayout: UICollectionViewLayout {
	
	static let controlGroupHeight: CGFloat = 32
	static let collectionItemHeight: CGFloat = 104
	
	fileprivate let controlSpacing: CGFloat = 20
	fileprivate let groupSpacing: CGFloat = 4
	
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
		
		if isSearching {
			createSearchCache(data: data)
			
		} else {
			createNormalCache(data: data)
		}
	}
	
	private func createNormalCache(data: NSDiffableDataSourceSnapshot<Int, AnyHashable>) {
		var yOffset: CGFloat = 0
		
		let numberOfSections = data.numberOfSections
		for groupIndex in 0..<numberOfSections {
			for (itemIndex, item) in data.itemIdentifiers(inSection: groupIndex).enumerated() {
				var frame = CGRect.zero
				if item is MenuViewController {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectiblesCollectionLayout.controlGroupHeight)
					yOffset += frame.size.height
					yOffset += controlSpacing
					
				} else if item is Token {
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
	
	private func createSearchCache(data: NSDiffableDataSourceSnapshot<Int, AnyHashable>) {
		var yOffset: CGFloat = 0
		
		let numberOfSections = data.numberOfSections
		for groupIndex in 0..<numberOfSections {
			for (itemIndex, item) in data.itemIdentifiers(inSection: groupIndex).enumerated() {
				var frame = CGRect.zero
				if item is MenuViewController {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectiblesCollectionLayout.controlGroupHeight)
					yOffset += frame.size.height
					yOffset += controlSpacing
					
				} else {
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
