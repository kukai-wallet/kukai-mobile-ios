//
//  CAGradientLayer+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/11/2022.
//

import UIKit

extension CAGradientLayer {
	
	/// Sets the start and end points on a gradient layer for a given angle.
	///
	/// - Important:
	/// *0°* is a horizontal gradient from left to right.
	///
	/// With a positive input, the rotational direction is clockwise.
	///
	///    * An input of *400°* will have the same output as an input of *40°*
	///
	/// With a negative input, the rotational direction is clockwise.
	///
	///    * An input of *-15°* will have the same output as *345°*
	///
	/// - Parameters:
	///     - angle: The angle of the gradient.
	///
	public func calculatePoints(for angle: CGFloat) {
		
		
		var ang = (-angle).truncatingRemainder(dividingBy: 360)
		
		if ang < 0 { ang = 360 + ang }
		
		let n: CGFloat = 0.5
		
		switch ang {
				
			case 0...45, 315...360:
				let a = CGPoint(x: 0, y: n * tanx(ang) + n)
				let b = CGPoint(x: 1, y: n * tanx(-ang) + n)
				startPoint = a
				endPoint = b
				
			case 45...135:
				let a = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
				let b = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
				startPoint = a
				endPoint = b
				
			case 135...225:
				let a = CGPoint(x: 1, y: n * tanx(-ang) + n)
				let b = CGPoint(x: 0, y: n * tanx(ang) + n)
				startPoint = a
				endPoint = b
				
			case 225...315:
				let a = CGPoint(x: n * tanx(-ang - 90) + n, y: 0)
				let b = CGPoint(x: n * tanx(ang - 90) + n, y: 1)
				startPoint = a
				endPoint = b
				
			default:
				let a = CGPoint(x: 0, y: n)
				let b = CGPoint(x: 1, y: n)
				startPoint = a
				endPoint = b
				
		}
	}
	
	/// Private function to aid with the math when calculating the gradient angle
	private func tanx(_ 𝜽: CGFloat) -> CGFloat {
		return tan(𝜽 * CGFloat.pi / 180)
	}
	
	
	// Overloads
	
	/// Sets the start and end points on a gradient layer for a given angle.
	public func calculatePoints(for angle: Int) {
		calculatePoints(for: CGFloat(angle))
	}
	
	/// Sets the start and end points on a gradient layer for a given angle.
	public func calculatePoints(for angle: Float) {
		calculatePoints(for: CGFloat(angle))
	}
	
	/// Sets the start and end points on a gradient layer for a given angle.
	public func calculatePoints(for angle: Double) {
		calculatePoints(for: CGFloat(angle))
	}
}
