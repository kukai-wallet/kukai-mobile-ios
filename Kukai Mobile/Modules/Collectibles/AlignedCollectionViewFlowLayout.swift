//
//  AlignedCollectionViewFlowLayout.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/10/2022.
//

import UIKit

class AlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		if let attrs = super.layoutAttributesForElements(in: rect) {
			var baseline: CGFloat = -2
			var sameLineElements = [UICollectionViewLayoutAttributes]()
			for element in attrs {
				if element.representedElementCategory == .cell {
					let frame = element.frame
					let centerY = frame.midY
					if abs(centerY - baseline) > 1 {
						baseline = centerY
						alignToTopForSameLineElements(sameLineElements: sameLineElements)
						sameLineElements.removeAll()
					}
					sameLineElements.append(element)
				}
			}
			alignToTopForSameLineElements(sameLineElements: sameLineElements) // align one more time for the last line
			return attrs
		}
		return nil
	}
	
	private func alignToTopForSameLineElements(sameLineElements: [UICollectionViewLayoutAttributes]) {
		if sameLineElements.count < 1 { return }
		let sorted = sameLineElements.sorted { (obj1: UICollectionViewLayoutAttributes, obj2: UICollectionViewLayoutAttributes) -> Bool in
			let height1 = obj1.frame.size.height
			let height2 = obj2.frame.size.height
			let delta = height1 - height2
			return delta <= 0
		}
		if let tallest = sorted.last {
			for obj in sameLineElements {
				obj.frame = obj.frame.offsetBy(dx: 0, dy: tallest.frame.origin.y - obj.frame.origin.y)
			}
		}
	}
	
	
	
	
	
	
	
	
	
	
	/*
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		if let attributes = super.layoutAttributesForElements(in: rect) {
			let sectionElements: [Int : [UICollectionViewLayoutAttributes]] = attributes
				.filter {
					return $0.representedElementCategory == .cell //take cells only
				}.groupBy {
					return $0.indexPath.section //group attributes by section
				}
			
			sectionElements.forEach { (section, elements) in
				//get suplementary view (header) to align each section
				let suplementaryView = attributes.first {
					return $0.representedElementCategory == .supplementaryView && $0.indexPath.section == section
				}
				//call align method
				alignToTopSameSectionElements(elements, with: suplementaryView)
			}
			
			return attributes
		}
		
		return super.layoutAttributesForElements(in: rect)
	}
	
	private func alignToTopSameSectionElements(_ elements: [UICollectionViewLayoutAttributes], with suplementaryView: UICollectionViewLayoutAttributes?) {
		//group attributes by colum
		let columElements: [Int : [UICollectionViewLayoutAttributes]] = elements.groupBy {
			return Int($0.frame.midX)
		}
		
		columElements.enumerated().forEach { (columIndex, object) in
			let columElement = object.value.sorted {
				return $0.indexPath < $1.indexPath
			}
			
			columElement.enumerated().forEach { (index, element) in
				var frame = element.frame
				
				if columIndex == 0 {
					frame.origin.x = minimumLineSpacing
				}
				
				switch index {
					case 0:
						if let suplementaryView = suplementaryView {
							frame.origin.y = suplementaryView.frame.maxY
						}
					default:
						let beforeElement = columElement[index-1]
						frame.origin.y = beforeElement.frame.maxY + minimumInteritemSpacing
				}
				
				element.frame = frame
			}
		}
	}*/
}

/*
public extension Array {
	
	func groupBy <U>(groupingFunction group: (Element) -> U) -> [U: Array] {
		var result = [U: Array]()
		
		for item in self {
			let groupKey = group(item)
			
			if result.keys.contains(groupKey) {
				result[groupKey]! += [item]
				
			} else {
				result[groupKey] = [item]
			}
		}
		
		return result
	}
}
*/
