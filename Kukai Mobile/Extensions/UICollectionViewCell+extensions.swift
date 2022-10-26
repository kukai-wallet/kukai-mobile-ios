//
//  UICollectionViewCell+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/10/2022.
//

import UIKit

extension UICollectionViewCell {
	
	func loadFromNib<T: UICollectionViewCell>(type: T) -> T? {
		let className = String(describing: self)
		let nib = Bundle.main.loadNibNamed(className, owner: self)
		
		if let cell = nib?.first as? T {
			return cell
		} else {
			return nil
		}
	}
	
	public static func loadFromNib<T: UICollectionViewCell>(named: String, ofType: T.Type) -> T? {
		let nib = Bundle.main.loadNibNamed(named, owner: self)
		
		if let cell = nib?.first as? T {
			return cell
		} else {
			return nil
		}
	}
}
