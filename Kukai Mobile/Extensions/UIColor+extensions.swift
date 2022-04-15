//
//  UIColor+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/04/2022.
//

import UIKit
import os.log

public class ThemeSelector {
	
	public enum Theme: String {
		case light
		case dark
		case red
		case blue
	}
	
	public static let shared = ThemeSelector()
	
	// Need to call `self.loadView()` on all open viewControllers
	public var selectedTheme: Theme = .light {
		didSet {
			if selectedTheme == .dark {
				UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = .dark
				
			} else {
				UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = .light
			}
		}
	}
	
	private init() {}
}






extension UIColor {
	
	private typealias oringnalShortFunc = @convention(c) (AnyObject, Selector, String) -> UIColor?
	private typealias oringnalLongFunc = @convention(c) (AnyObject, Selector, String, Bundle, UITraitCollection) -> UIColor?
	
	private static let originalShortSelector = #selector(UIColor.init(named:))
	private static let originalLongSelector = #selector(UIColor.init(named:in:compatibleWith:))
	
	private static let swizzledShortSelector = #selector(theme_color(named:))
	private static let swizzledLongSelector = #selector(theme_color(named:inBundle:compatibleWithTraitCollection:))
	
	private static var originalShortImplementation = class_getMethodImplementation(UIColor.self, UIColor.originalShortSelector)
	private static var originalLongImplementation = class_getMethodImplementation(UIColor.self, UIColor.originalLongSelector)
	
	
	
	class func swizzleNamedColorInitToAddTheme() {
		guard let originalShortMethod = class_getClassMethod(self, originalShortSelector),
			  let originalLongMethod = class_getClassMethod(self, originalLongSelector),
			  let swizzledShortMethod = class_getInstanceMethod(self, swizzledShortSelector),
			  let swizzledLongMethod = class_getInstanceMethod(self, swizzledLongSelector) else {
			os_log("Unable to find UIColor methods to swizzle", log: .default, type: .error)
			return
		}
		
		// Swap oringal methods
		method_exchangeImplementations(originalShortMethod, swizzledShortMethod);
		method_exchangeImplementations(originalLongMethod, swizzledLongMethod);
		
		// Hold onto references of oringal methods
		originalShortImplementation = class_getMethodImplementation(UIColor.self, UIColor.swizzledShortSelector)
		originalLongImplementation = class_getMethodImplementation(UIColor.self, UIColor.swizzledLongSelector)
	}
	
	@objc func theme_color(named name: String) -> UIColor? {
		let newName = "\(ThemeSelector.shared.selectedTheme.rawValue)_\(name)"
		
		print("Checking for name 1: \(newName)")
		
		// Call the orignal UIColor(named: ...) with the new, automatically prefixed, color name
		return unsafeBitCast(UIColor.originalShortImplementation, to: oringnalShortFunc.self)(self, UIColor.originalShortSelector, newName)
	}
	
	@objc func theme_color(named name: String, inBundle: Bundle, compatibleWithTraitCollection: UITraitCollection) -> UIColor? {
		let newName = "\(ThemeSelector.shared.selectedTheme.rawValue)_\(name)"
		
		print("Checking for name 2: \(newName)")
		
		// Call the orignal UIColor(named: ...) with the new, automatically prefixed, color name
		return unsafeBitCast(UIColor.originalLongImplementation, to: oringnalLongFunc.self)(self, UIColor.originalLongSelector, newName, inBundle, compatibleWithTraitCollection)
	}
}
