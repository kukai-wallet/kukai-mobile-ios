//
//  UISegmentedControl+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit

extension UISegmentedControl {
	
	func removeBorder() {
		let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: self.bounds.size)
		self.setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
		self.setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
		self.setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)
		
		let dividerImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: self.bounds.size.height))
		self.setDividerImage(dividerImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
	}
	
	func setFonts(selectedFont: UIFont, selectedColor: UIColor, defaultFont: UIFont, defaultColor: UIColor) {
		self.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: defaultColor,
			NSAttributedString.Key.font: defaultFont
		], for: .normal)
		self.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: selectedColor,
			NSAttributedString.Key.font: selectedFont
		], for: .selected)
	}
	
	func addUnderlineForSelectedSegment() {
		removeBorder()
		setFonts(selectedFont: UIFont.custom(ofType: .bold, andSize: 16), selectedColor: UIColor.colorNamed("Txt2"), defaultFont: UIFont.custom(ofType: .bold, andSize: 16), defaultColor: UIColor.colorNamed("TxtB6"))
		
		let underlineWidth: CGFloat = self.bounds.size.width / CGFloat(self.numberOfSegments)
		let underlineHeight: CGFloat = 2.0
		let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
		let underLineYPosition = self.bounds.size.height - (underlineHeight * 2)
		let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
		let underline = UIView(frame: underlineFrame)
		underline.backgroundColor = UIColor.colorNamed("BGB6")
		underline.tag = 1
		self.clipsToBounds = false
		self.layer.masksToBounds = false
		self.addSubview(underline)
	}
	
	func changeUnderlinePosition() {
		guard let underline = self.viewWithTag(1) else {return}
		let underlineFinalXPosition = (self.bounds.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
		UIView.animate(withDuration: 0.1, animations: {
			underline.frame.origin.x = underlineFinalXPosition
		})
	}
}
