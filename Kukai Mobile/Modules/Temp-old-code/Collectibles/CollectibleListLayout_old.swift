//
//  CollectibleListLayoutOld.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/12/2022.
//

/*
import UIKit
import KukaiCoreSwift

protocol CollectibleListLayoutDelegate: AnyObject {
	func data() -> NSDiffableDataSourceSnapshot<Int, AnyHashable>
}

class CollectibleListLayoutOld: UICollectionViewLayout {
	
	static let controlGroupHeight: CGFloat = 54
	static let specialGroupHeight: CGFloat = 64
	static let groupHeight: CGFloat = 64
	static let itemHeight: CGFloat = 94
	static let ghostnetWarningHeight: CGFloat = 52
	static let searchItemHeight: CGFloat = 88
	
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
	
	public weak var delegate: CollectibleListLayoutDelegate?
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
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.controlGroupHeight)
					
				} else if item is GhostnetWarningCellObj {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.ghostnetWarningHeight)
					
				} else if item is SpecialGroupData {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.specialGroupHeight)
					
				} else if item is Token {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.groupHeight)
					
				} else {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.itemHeight)
				}
				
				let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: itemIndex, section: groupIndex))
				attributes.frame = frame
				cache[groupIndex].append(attributes)
				
				yOffset += frame.size.height
			}
			
			yOffset += groupSpacing
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
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.controlGroupHeight)
					
				} else if item is GhostnetWarningCellObj {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.ghostnetWarningHeight)
					
				} else {
					frame = CGRect(x: 0, y: yOffset, width: contentWidth, height: CollectibleListLayout.searchItemHeight)
				}
				
				let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: itemIndex, section: groupIndex))
				attributes.frame = frame
				cache[groupIndex].append(attributes)
				
				yOffset += frame.size.height
			}
			
			yOffset += groupSpacing
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