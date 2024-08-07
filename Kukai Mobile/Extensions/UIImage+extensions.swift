//
//  UIImage+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit

extension UIImage {
	
	func maskWithColor(color: UIColor) -> UIImage? {
		let maskImage = cgImage!
		
		let width = size.width
		let height = size.height
		let bounds = CGRect(x: 0, y: 0, width: width, height: height)
		
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
		let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
		
		context.clip(to: bounds, mask: maskImage)
		context.setFillColor(color.cgColor)
		context.fill(bounds)
		
		if let cgImage = context.makeImage() {
			let coloredImage = UIImage(cgImage: cgImage)
			return coloredImage
		} else {
			return nil
		}
	}
	
	func resizedImage(size sizeImage: CGSize) -> UIImage? {
		return UIGraphicsImageRenderer(size: sizeImage).image { _ in
			self.draw(in: CGRect(origin: .zero, size: sizeImage))
		}
	}
	
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
	
	class func tezosToken() -> UIImage {
		return UIImage(named: "Social_TZ_Ovalcolor") ?? UIImage()
	}
	
	class func unknownToken() -> UIImage {
		return UIImage(named: "missingImage")?.resizedImage(size: CGSize(width: 52, height: 52)) ?? UIImage()
	}
	
	class func unknownThumb() -> UIImage {
		return UIImage(named: "missingImage") ?? UIImage()
	}
	
	class func unknownGroup() -> UIImage {
		return UIImage(named: "missingImageGroup") ?? UIImage()
	}
	
	class func animationFrames(prefix: String, count: Int) -> [UIImage] {
		var tempArray: [UIImage] = []
		
		for index in 0..<count {
			tempArray.appendIfPresent(UIImage(named: prefix+String(format: "%02d", index)))
		}
		
		return tempArray
	}
	
	func addBlur() -> UIImage? {
		guard let ciImg = CIImage(image: self) else { return nil }
		
		if let cgImage = blurredImage(image: ciImg, radius: 10) {
			return UIImage(cgImage: cgImage)
		}
		
		return nil
	}
	
	func blurredImage(image: CIImage, radius: CGFloat) -> CGImage? {
		let coreImageContext = CIContext()
		
		let blurredImage = image
			.clampedToExtent()
			.applyingFilter(
				"CIGaussianBlur",
				parameters: [
					kCIInputRadiusKey: radius,
				]
			)
			.cropped(to: image.extent)
		
		return coreImageContext.createCGImage(blurredImage, from: blurredImage.extent)
	}
}
