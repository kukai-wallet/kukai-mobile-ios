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
		
		let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: self.bounds.size.height))
		self.setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
		self.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Brand1000"),
			NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 16)
		], for: .normal)
		self.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Grey200"),
			NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 16)
		], for: .selected)
	}
	
	func addUnderlineForSelectedSegment() {
		removeBorder()
		let underlineWidth: CGFloat = self.bounds.size.width / CGFloat(self.numberOfSegments)
		let underlineHeight: CGFloat = 2.0
		let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
		let underLineYPosition = self.bounds.size.height - (underlineHeight * 2)
		let underlineFrame = CGRect(x: underlineXPosition, y: underLineYPosition, width: underlineWidth, height: underlineHeight)
		let underline = UIView(frame: underlineFrame)
		underline.backgroundColor = UIColor.colorNamed("Brand800")
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

extension UIImage {
	
	class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		let graphicsContext = UIGraphicsGetCurrentContext()
		graphicsContext?.setFillColor(color)
		let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
		graphicsContext?.fill(rectangle)
		let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return rectangleImage!
	}
}
