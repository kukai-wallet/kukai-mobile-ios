//
//  ThemeManager.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/04/2022.
//

import UIKit
import os.log

public protocol ThemeManagerDelegate: AnyObject {
	func themeDidChange(to: String)
}

/**
 A simple class to hold onto a collection of theme colors and persist the users choice to UserDefaults
 */
public class ThemeManager {
	
	public struct ThemeData {
		let interfaceStyle: UIUserInterfaceStyle
		let namedColors: [String: UIColor]
	}
	
	public static let shared = ThemeManager()
	public weak var delegate: ThemeManagerDelegate? = nil
	
	private var themes: [String: ThemeData] = [:]
	private var selectedTheme: String = UserDefaults.standard.string(forKey: "app.kukai.mobile.theme") ?? (UITraitCollection.current.userInterfaceStyle == .light ? "Light" : "Dark")
	
	private init() {}
	
	public func availableThemes() -> [String] {
		let removedStandards = themes.map{String($0.key)}.filter { str in
			if str == "Light" || str == "Dark" {
				return false
			}
			
			return true
		}
		
		// Ensure Light and Dark are always top two options
		var temp = ["Light", "Dark"]
		temp.append(contentsOf: removedStandards)
		
		return temp
	}
	
	public func currentTheme() -> String {
		return selectedTheme
	}
	
	public func setTheme(_ theme: String) {
		UserDefaults.standard.setValue(theme, forKey: "app.kukai.mobile.theme")
		selectedTheme = theme
		updateSystemInterfaceStyle()
		
		self.delegate?.themeDidChange(to: theme)
		
		// Deleting and re-adding all views on the screen is an old "trick" to get colors to refresh.
		// It only works for things using appearence proxy, it doesn't reload our colors.
		// So we call the delegate to notifiy the app that the theme has changed, let the app resetup appearence proxies (because they cache the color object, not the name)
		// then reload the views, so that the new appearence is picked up.
		// APp will need to reload its content (likely by popping to root)
		let window = UIApplication.shared.currentWindow
		for view in window?.subviews ?? [] {
			view.removeFromSuperview()
			window?.addSubview(view)
		}
	}
	
	public func setup(lightColors: [String: UIColor], darkColors: [String: UIColor], others: [String: ThemeData]) {
		self.themes["Light"] = ThemeData(interfaceStyle: .light, namedColors: lightColors)
		self.themes["Dark"] = ThemeData(interfaceStyle: .dark, namedColors: darkColors)
		self.themes.merge(others) { current, _ in current }
		
		// Swizzle after colors created to avoid issues during setup
		UIColor.swizzleNamedColorInitToAddTheme()
	}
	
	public func color(named: String) -> UIColor? {
		if let color = self.themes[self.selectedTheme]?.namedColors[named] {
			return color
		}
		
		os_log("Unable to find color: %@, for Theme: %@", log: .default, type: .error, named, selectedTheme)
		return nil
	}
	
	public func updateSystemInterfaceStyle() {
		UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = self.themes[self.selectedTheme]?.interfaceStyle ?? UITraitCollection.current.userInterfaceStyle
	}
}

/**
 Extension to add hex string constructor (with optional alpha)
 */
public extension UIColor {
		
	convenience init(_ hex: String, alpha: CGFloat = 1.0) {
		var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		
		if cString.hasPrefix("#") { cString.removeFirst() }
		
		if cString.count != 6 {
			self.init("ff0000") // return red color for wrong hex input
			return
		}
		
		var rgbValue: UInt64 = 0
		Scanner(string: cString).scanHexInt64(&rgbValue)
		
		self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
				  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
				  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
				  alpha: alpha)
	}
}


/**
 Extension to swizzle the `UIColor(named: "")` constructors, so that they read from `ThemeManager.shared.color(named: "")` instead
 */
private extension UIColor {
	
	private static let originalShortSelector = #selector(UIColor.init(named:))
	private static let originalLongSelector = #selector(UIColor.init(named:in:compatibleWith:))
	
	private static let swizzledShortSelector = #selector(theme_color(named:))
	private static let swizzledLongSelector = #selector(theme_color(named:inBundle:compatibleWithTraitCollection:))
	
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
	}
	
	@objc func theme_color(named name: String) -> UIColor? {
		return ThemeManager.shared.color(named: name)
	}
	
	@objc func theme_color(named name: String, inBundle: Bundle, compatibleWithTraitCollection: UITraitCollection) -> UIColor? {
		return ThemeManager.shared.color(named: name)
	}
}





// Previous implementation, which only partially swizzles methods, to prefix color with theme named. Caused some issues, holding onto for now
/*
public class ThemeSelector {
	
	public enum Theme: String {
		case light = "Light"
		case dark = "Dark"
		case red = "Red"
		case blue = "Blue"
	}
	
	public static let shared = ThemeSelector()
	private static var selectedTheme: Theme = (Theme(rawValue: UserDefaults.standard.string(forKey: "app.kukai.mobile.theme") ?? "") ?? .light)
	
	public func currentTheme() -> Theme {
		return ThemeSelector.selectedTheme
	}
	
	public func set(theme: Theme) {
		UserDefaults.standard.setValue(theme.rawValue, forKey: "app.kukai.mobile.theme")
		ThemeSelector.selectedTheme = theme
		updateSystemInterfaceStyle()
	}
	
	public func updateSystemInterfaceStyle() {
		if ThemeSelector.selectedTheme == .dark {
			UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = .dark
			
		} else {
			UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = .light
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
		let newName = "\(ThemeSelector.shared.currentTheme().rawValue)_\(name)"
		
		// Call the orignal UIColor(named: ...) with the new, automatically prefixed, color name
		return unsafeBitCast(UIColor.originalShortImplementation, to: oringnalShortFunc.self)(self, UIColor.originalShortSelector, newName)
	}
	
	@objc func theme_color(named name: String, inBundle: Bundle, compatibleWithTraitCollection: UITraitCollection) -> UIColor? {
		let newName = "\(ThemeSelector.shared.currentTheme().rawValue)_\(name)"
		
		// Call the orignal UIColor(named: ...) with the new, automatically prefixed, color name
		return unsafeBitCast(UIColor.originalLongImplementation, to: oringnalLongFunc.self)(self, UIColor.originalLongSelector, newName, inBundle, compatibleWithTraitCollection)
	}
}
*/
