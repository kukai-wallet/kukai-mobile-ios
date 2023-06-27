//
//  ShimmerView.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/04/2023.
//

import UIKit

class ShimmerView: UIView {
	
	var startLocations: [NSNumber] = [-1.0, -0.5, 0.0]
	var endLocations: [NSNumber] = [1.0, 1.5, 2.0]
	
	var gradientBackgroundColor = UIColor.colorNamed("BG4").cgColor
	var gradientMovingColor = UIColor.colorNamed("BG6").cgColor
	
	var movingAnimationDuration: CFTimeInterval = 0.8
	var delayBetweenAnimationLoops: CFTimeInterval = 1.0
	
	var gradientLayer = CAGradientLayer()
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		
		if gradientLayer.superlayer != nil { return }
		
		gradientLayer.frame = self.bounds
		gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
		gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradientLayer.colors = [
			gradientBackgroundColor,
			gradientMovingColor,
			gradientBackgroundColor
		]
		gradientLayer.locations = self.startLocations
		self.layer.addSublayer(gradientLayer)
	}
	
	func reloadForThemeChange() {
		gradientBackgroundColor = UIColor.colorNamed("BG4").cgColor
		gradientMovingColor = UIColor.colorNamed("BG6").cgColor
		
		gradientLayer.removeFromSuperlayer()
		draw(self.bounds)
		startAnimating()
	}
	
	func startAnimating() {
		let animation = CABasicAnimation(keyPath: "locations")
		animation.fromValue = self.startLocations
		animation.toValue = self.endLocations
		animation.duration = self.movingAnimationDuration
		animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
		
		let animationGroup = CAAnimationGroup()
		animationGroup.duration = self.movingAnimationDuration + self.delayBetweenAnimationLoops
		animationGroup.animations = [animation]
		animationGroup.repeatCount = .infinity
		self.gradientLayer.add(animationGroup, forKey: animation.keyPath)
	}
	
	func stopAnimating() {
		self.gradientLayer.removeAllAnimations()
		self.gradientLayer.removeFromSuperlayer()
	}
}
