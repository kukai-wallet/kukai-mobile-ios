//
//  ThemeManager.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/04/2022.
//

import UIKit
import os.log

/**
 A simple class to hold onto a collection of theme colors and persist the users choice to UserDefaults
 */
public class ThemeManager {
	
	@Published public var themeDidChange: Bool = false
	
	public struct ThemeData {
		let interfaceStyle: UIUserInterfaceStyle
		let namedColors: [String: UIColor]
	}
	
	public static let shared = ThemeManager()
	
	public var themes: [String: ThemeData] = [:]
	private var selectedTheme: String = UserDefaults.standard.string(forKey: "app.kukai.mobile.theme") ?? "Dark"
	
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
		
		self.themeDidChange = true
		
		// Deleting and re-adding all views on the screen is an old "trick" to get colors to refresh.
		// It only works for things using appearence proxy, it doesn't reload our colors.
		// So we call the delegate to notifiy the app that the theme has changed, let the app resetup appearence proxies (because they cache the color object, not the name)
		// then reload the views, so that the new appearence is picked up.
		// App will need to reload its content (likely by popping to root)
		let window = UIApplication.shared.currentWindow
		for view in window?.subviews ?? [] {
			view.removeFromSuperview()
			window?.addSubview(view)
		}
	}
	
	public func setup() {
		ThemeManager.shared.setup(
			lightColors: [
				
				"BrandColorTrue": UIColor("#5963FF"),
				
				// Default Text
				"Txt0": UIColor("#000000"),
				"Txt2": UIColor("#1C1C27"),
				"Txt4": UIColor("#2D2E3F"),
				"Txt6": UIColor("#4E5066"),
				"Txt8": UIColor("#696A80"),
				"Txt10": UIColor("#88889E"),
				"Txt12": UIColor("#9A9BA8"),
				"Txt14": UIColor("#B2B4D1"),
				"TxtMenuContext": UIColor("#2D2E3F"),
				"TxtMenuTitleContext": UIColor("#88889E"),
				"TxtQuantity": UIColor("#2D2E3F"),
				"TxtSale": UIColor("#FFFFFF"),
				"TxtTestState": UIColor("#FFFFFF"),
				
				// Button Text
				"TxtBtnPrim1": UIColor("#FFFFFF"),
				"TxtBtnPrim2": UIColor("#FFFFFF"),
				"TxtBtnPrim3": UIColor("#FFFFFF"),
				"TxtBtnPrim4": UIColor("#AFB2BC"),
				"TxtBtnSec1": UIColor("#1C1C27"),
				"TxtBtnSec2": UIColor("#4F4F4F"),
				"TxtBtnSec3": UIColor("#000000"),
				"TxtBtnSec4": UIColor("#C0C4CF"),
				"TxtBtnSecSel1": UIColor("#1C1C27"),
				"TxtBtnTer1": UIColor("#1C1C27"),
				"TxtBtnTer2": UIColor("#1C1C27"),
				"TxtBtnTer3": UIColor("#1C1C27"),
				"TxtBtnTer4": UIColor("#C0C4CF"),
				"TxtBtnMicroB1": UIColor("#6D75F4"),
				"TxtBtnMicroB2": UIColor("#6D75F4"),
				"TxtBtnMicroB3": UIColor("#6D75F4"),
				"TxtBtnMicroB4": UIColor("#6D75F4"),
				"TxtBtnMicro1": UIColor("#86889D"),
				"TxtBtnMicro2": UIColor("#86889D"),
				"TxtBtnMicro3": UIColor("#86889D"),
				"TxtBtnMicro4": UIColor("#86889D"),
				"TxtBtnGraph1": UIColor("#6D75F4"),
				"TxtBtnGraphOn1": UIColor("#696A80"),
				"TxtBtnSlider1": UIColor("#343994"),
				"TxtBtnSlider2": UIColor("#343994"),
				"TxTBtnAlert1": UIColor("#383838"),
				"TxTBtnAlert4": UIColor("#383838"),
				"TxtLink": UIColor("#6D75F4"),
				
				// Coloured Text
				"TxtB2": UIColor("#555CCA"),
				"TxtB4": UIColor("#5C65F0"),
				"TxtB6": UIColor("#6D75F4"),
				"TxtB8": UIColor("#A4A8F1"),
				"TxtAlert2": UIColor("#9F274B"),
				"TxtAlert4": UIColor("#D34C74"),
				"TxtAlert6": UIColor("#FF759E"),
				"TxtGood2": UIColor("#097B37"),
				"TxtGood4": UIColor("#00A441"),
				"TxtGood6": UIColor("#39E87F"),
				"TxtB-alt2": UIColor("#DA9201"),
				"TxtB-alt4": UIColor("#F3AA19"),
				"TxtB-alt6": UIColor("#FFD073"),
				
				// Buttons background
				"BtnPrim1-1": UIColor("#626AED"),
				"BtnPrim1-2": UIColor("#7812FC"),
				"BtnPrim3-1": UIColor("#575ED4"),
				"BtnPrim3-2": UIColor("#7926E3"),
				"BtnPrim4-1": UIColor("#E3E4F8"),
				"BtnPrim4-2": UIColor("#D9D7EC"),
				"BtnSec1": UIColor("#FFFFFF", alpha: 0.6),
				"BtnSec2": UIColor("#E5E5E5", alpha: 0.6),
				"BtnSec3": UIColor("#CCCCCC", alpha: 0.6),
				"BtnSec4": UIColor("#FFFFFF", alpha: 0.2),
				"BtnStrokeSec1": UIColor("#6D75F4"),
				"BtnStrokeSec2": UIColor("#6D75F4"),
				"BtnStrokeSec3": UIColor("#6D75F4"),
				"BtnStrokeSec4": UIColor("#6D75F4"),
				"BtnSecSel1": UIColor("#FFFFFF", alpha: 0.2),
				"BtnStrokeSecSel1": UIColor("#979797"),
				"BtnTer1": UIColor("#FFFFFF", alpha: 0.6),
				"BtnTer2": UIColor("#E5E5E5", alpha: 0.6),
				"BtnTer3": UIColor("#000000", alpha: 0.2),
				"BtnTer4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeTer1-1": UIColor("#626AED"),
				"BtnStrokeTer1-2": UIColor("#862AFC"),
				"BtnStrokeTer3-1": UIColor("#626AED"),
				"BtnStrokeTer3-2": UIColor("#862AFC"),
				"BtnStrokeTer4-1": UIColor("#D5D7F0"),
				"BtnStrokeTer4-2": UIColor("#C6C8DD"),
				"BtnMicro1": UIColor("#F1F1F4"),
				"BtnMicro2": UIColor("#F1F1F4"),
				"BtnMicro3": UIColor("#F1F1F4"),
				"BtnMicro4": UIColor("#F1F1F4"),
				"BtnStrokeMicro1": UIColor("#BBBCD7"),
				"BtnStrokeMicro2": UIColor("#BBBCD7"),
				"BtnStrokeMicro3": UIColor("#BBBCD7"),
				"BtnStrokeMicro4": UIColor("#BBBCD7"),
				"BtnMicroB1": UIColor("#FFFFFF"),
				"BtnMicroB2": UIColor("#FFFFFF"),
				"BtnMicroB3": UIColor("#FFFFFF"),
				"BtnMicroB4": UIColor("#FFFFFF"),
				"BtnStrokeMicroB1": UIColor("#6D75F4"),
				"BtnStrokeMicroB2": UIColor("#6D75F4"),
				"BtnStrokeMicroB3": UIColor("#6D75F4"),
				"BtnStrokeMicroB4": UIColor("#6D75F4"),
				"BtnGraph1": UIColor("#F1F1F4"),
				"BtnGraphB1": UIColor("#FFFFFF"),
				"BtnAlert1": UIColor("#FFFFFF", alpha: 0.6),
				"BtnStrokeAlert1": UIColor("#D34C74"),
				"BtnAlert4": UIColor("#FFFFFF", alpha: 0.6),
				"BtnStrokeAlert4": UIColor("#D34C74"),
				
				// Slider Button
				"gradSliderCircle-1": UIColor("#FFFFFF"),
				"gradSliderCircle-2": UIColor("#DFE1FF"),
				"gradStrokeSlider-1": UIColor("#767DF0"),
				"gradStrokeSlider-2": UIColor("#5A61D9"),
				"BGBtn_Slider": UIColor("#4954FF", alpha: 0.07),
				"BGBtn_SliderFill": UIColor("#6D75F4", alpha: 0.45),
				
				// Gradient
				"gradBgFull-1": UIColor("#FFFFFF"),
				"gradBgFull-2": UIColor("#F5F6FF"),
				"gradBgFull-3": UIColor("#E9EAF2"),
				"gradModal-1": UIColor("#FFFFFF"),
				"gradModal-2": UIColor("#EEEFF7"),
				"gradModal-3": UIColor("#E4E5ED"),
				"gradTabBar-1": UIColor("#FAFAFF"),
				"gradTabBar-2": UIColor("#F2F3FC"),
				"gradTabBar_Highlight-1": UIColor("#9A98FF", alpha: 0.2),
				"gradTabBar_Highlight-2": UIColor("#8A9CFE", alpha: 0),
				"gradPanelRows-1": UIColor("#FFFFFF", alpha: 0.84),
				"gradPanelRows-2": UIColor("#FFFFFF", alpha: 0.53),
				"gradPanelRows_Black-1": UIColor("#C0C0CE", alpha: 0.13),
				"gradPanelRows_Black-2": UIColor("#D2D2DB", alpha: 0.1),
				"gradNavBarPanels-1": UIColor("#F5F5FF"),
				"gradNavBarPanels-2": UIColor("#F8F8FD"),
				"gradStroke_NavBarPanels-1": UIColor("#BCBDD1"),
				"gradStroke_NavBarPanels-2": UIColor("#BCBDD1"),
				"gradPanelAttributes-1": UIColor("#FFFFFF", alpha: 0.5),
				"gradPanelAttributes-2": UIColor("#FFFFFF", alpha: 0.2),
				"gradExpBorderTop-1": UIColor("#777FEE"),
				"gradExpBorderTop-2": UIColor("#858CED"),
				"gradExpBorderMiddle-1": UIColor("#858CED"),
				"gradExpBorderMiddle-2": UIColor("#858CED"),
				"gradExpBorderBottom-1": UIColor("#858CED"),
				"gradExpBorderBottom-2": UIColor("#B0B5FF"),
				"gradGraphToken-1": UIColor("#555CCA", alpha: 0.48),
				"gradGraphToken-2": UIColor("#555CCA", alpha: 0),
				"gradUnconfirmed-1": UIColor("#D3D3E8", alpha: 0.55),
				"gradUnconfirmed-2": UIColor("#DADAF0", alpha: 0.29),
				"gradActivityIcons-1": UIColor("#767CE0", alpha: 0.45),
				"gradActivityIcons-2": UIColor("#8280EC", alpha: 0.75),
				
				// Media player
				"playerKnob": UIColor("#FFFFFF"),
				"playerFill": UIColor("#5F69F1"),
				"playerFillInset": UIColor("#88889E"),
				"playerIconSlider": UIColor("#5F69F1"),
				
				// Background
				"BG0": UIColor("#000000"),
				"BG1": UIColor("#F0F2F7"),
				"BG2": UIColor("#EAEBF0"),
				"BG3": UIColor("#EEEEFC"),
				"BG4": UIColor("#DFE0F0"),
				"BG6": UIColor("#BDBED9"),
				"BG8": UIColor("#A9ACC7"),
				"BG10": UIColor("#83839E"),
				"BG12": UIColor("#63647D"),
				"BG20": UIColor("#000000"),
				"BGB0": UIColor("#A8ADFF"),
				"BGB2": UIColor("#868CF7"),
				"BGB4": UIColor("#5F69F1"),
				"BGB6": UIColor("#5058DA"),
				"BGB8": UIColor("#343994"),
				"BGGood2": UIColor("#39E87F"),
				"BGGood4": UIColor("#09AE4B"),
				"BGGood6": UIColor("#097B37"),
				"BGAlert0": UIColor("#FFD3E1"),
				"BGAlert1": UIColor("#FA9CB8"),
				"BGAlert2": UIColor("#FF759E"),
				"BGAlert4": UIColor("#C12453"),
				"BGAlert6": UIColor("#9F274B"),
				"BGB-alt0": UIColor("#FFE6B5"),
				"BGB-alt2": UIColor("#FBC75F"),
				"BGB-alt4": UIColor("#EAA00C"),
				"BGB-alt6": UIColor("#EAA00C"),
				"BGMenuContext": UIColor("#F7F8FF"),
				"LineMenuContext": UIColor("#EBEBFF"),
				"BGInputs": UIColor("#DFE0F0"),
				"BGPanelExpand": UIColor("#FFFFFF"),
				"TintGeneral": UIColor("#333333", alpha: 0.75),
				"TintContext": UIColor("#000000", alpha: 0.2),
				"BGQunatity": UIColor("#EDEEFF"),
				"BGSale": UIColor("#6D75F4"),
				"BGLock": UIColor("#EEEFFF"),
				"BGThumbNFT": UIColor("#E4E8F3", alpha: 0.5),
				"BGFullNFT": UIColor("#CBCFD9", alpha: 0.5),
				"BGSideMenu": UIColor("#FAFAFC"),
				"BGTestState": UIColor("#FF5D29"),
				"BGRecoveryTrans": UIColor("#C6C7D7", alpha: 0.65),
				"BGActivityBatch": UIColor("#B7B9EA", alpha: 0.3),
				"BGMediaOval": UIColor("#000000"),
			],
			darkColors: [
				
				"BrandColorTrue": UIColor("#5963FF"),
				
				// Default Text
				"Txt0": UIColor("#FFFFFF"),
				"Txt2": UIColor("#F6F6FA"),
				"Txt4": UIColor("#E9EAF5"),
				"Txt6": UIColor("#D5D6E8"),
				"Txt8": UIColor("#BCBED4"),
				"Txt10": UIColor("#86889D"),
				"Txt12": UIColor("#696A80"),
				"Txt14": UIColor("#4E5066"),
				"TxtMenuContext": UIColor("#E9EAF5"),
				"TxtMenuTitleContext": UIColor("#86889D"),
				"TxtQuantity": UIColor("#2D2E3F"),
				"TxtSale": UIColor("#FFFFFF"),
				"TxtTestState": UIColor("#FFFFFF"),
				
				// Button Text
				"TxtBtnPrim1": UIColor("#FFFFFF"),
				"TxtBtnPrim2": UIColor("#FFFFFF"),
				"TxtBtnPrim3": UIColor("#FFFFFF"),
				"TxtBtnPrim4": UIColor("#6D6D6D"),
				"TxtBtnSec1": UIColor("#F6F6FA"),
				"TxtBtnSec2": UIColor("#FFFFFF"),
				"TxtBtnSec3": UIColor("#FFFFFF"),
				"TxtBtnSec4": UIColor("#6D6D6D"),
				"TxtBtnSecSel1": UIColor("#F6F6FA"),
				"TxtBtnTer1": UIColor("#F6F6FA"),
				"TxtBtnTer2": UIColor("#FFFFFF"),
				"TxtBtnTer3": UIColor("#FFFFFF"),
				"TxtBtnTer4": UIColor("#6D6D6D"),
				"TxtBtnMicroB1": UIColor("#6D75F4"),
				"TxtBtnMicroB2": UIColor("#6D75F4"),
				"TxtBtnMicroB3": UIColor("#6D75F4"),
				"TxtBtnMicroB4": UIColor("#6D75F4"),
				"TxtBtnMicro1": UIColor("#86889D"),
				"TxtBtnMicro2": UIColor("#86889D"),
				"TxtBtnMicro3": UIColor("#86889D"),
				"TxtBtnMicro4": UIColor("#86889D"),
				"TxtBtnGraph1": UIColor("#6D75F4"),
				"TxtBtnGraphOn1": UIColor("#86889D"),
				"TxtBtnSlider1": UIColor("#F6F6FA"),
				"TxtBtnSlider2": UIColor("#F6F6FA"),
				"TxTBtnAlert1": UIColor("#D5D6E8"),
				"TxTBtnAlert4": UIColor("#D5D6E8"),
				"TxtLink": UIColor("#6D75F4"),
				
				// Coloured Text
				"TxtB2": UIColor("#B9BDFF"),
				"TxtB4": UIColor("#9298FF"),
				"TxtB6": UIColor("#6D75F4"),
				"TxtB8": UIColor("#555CCA"),
				"TxtAlert2": UIColor("#FF759E"),
				"TxtAlert4": UIColor("#D34C74"),
				"TxtAlert6": UIColor("#9F274B"),
				"TxtGood2": UIColor("#39E87F"),
				"TxtGood4": UIColor("#09AE4B"),
				"TxtGood6": UIColor("#097B37"),
				"TxtB-alt2": UIColor("#FFDB82"),
				"TxtB-alt4": UIColor("#F9C848"),
				"TxtB-alt6": UIColor("#D69B03"),
				
				// Buttons background
				"BtnPrim1-1": UIColor("#626AED"),
				"BtnPrim1-2": UIColor("#862AFC"),
				"BtnPrim3-1": UIColor("#575ED4"),
				"BtnPrim3-2": UIColor("#7926E3"),
				"BtnPrim4-1": UIColor("#303139"),
				"BtnPrim4-2": UIColor("#24242D"),
				"BtnSec1": UIColor("#000000", alpha: 0.2),
				"BtnSec2": UIColor("#808080", alpha: 0.3),
				"BtnSec3": UIColor("#CCCCCC", alpha: 0.35),
				"BtnSec4": UIColor("#333232", alpha: 0.2),
				"BtnStrokeSec1": UIColor("#6D75F4"),
				"BtnStrokeSec2": UIColor("#6D75F4"),
				"BtnStrokeSec3": UIColor("#6D75F4"),
				"BtnStrokeSec4": UIColor("#3D3D3E"),
				"BtnSecSel1": UIColor("#000000", alpha: 0.2),
				"BtnStrokeSecSel1": UIColor("#4E5066"),
				"BtnTer1": UIColor("#000000", alpha: 0.2),
				"BtnTer2": UIColor("#808080", alpha: 0.3),
				"BtnTer3": UIColor("#CCCCCC", alpha: 0.35),
				"BtnTer4": UIColor("#000000", alpha: 0.2),
				"BtnStrokeTer1-1": UIColor("#626AED"),
				"BtnStrokeTer1-2": UIColor("#862AFC"),
				"BtnStrokeTer3-1": UIColor("#626AED"),
				"BtnStrokeTer3-2": UIColor("#862AFC"),
				"BtnStrokeTer4-1": UIColor("#35363A"),
				"BtnStrokeTer4-2": UIColor("#272529"),
				"BtnMicro1": UIColor("#22222E"),
				"BtnMicro2": UIColor("#22222E"),
				"BtnMicro3": UIColor("#22222E"),
				"BtnMicro4": UIColor("#22222E"),
				"BtnStrokeMicro1": UIColor("#3E3F50"),
				"BtnStrokeMicro2": UIColor("#3E3F50"),
				"BtnStrokeMicro3": UIColor("#3E3F50"),
				"BtnStrokeMicro4": UIColor("#3E3F50"),
				"BtnMicroB1": UIColor("#14141D"),
				"BtnMicroB2": UIColor("#14141D"),
				"BtnMicroB3": UIColor("#14141D"),
				"BtnMicroB4": UIColor("#14141D"),
				"BtnStrokeMicroB1": UIColor("#343994"),
				"BtnStrokeMicroB2": UIColor("#343994"),
				"BtnStrokeMicroB3": UIColor("#343994"),
				"BtnStrokeMicroB4": UIColor("#343994"),
				"BtnGraph1": UIColor("#14141D"),
				"BtnGraphB1": UIColor("#14141D"),
				"BtnAlert1": UIColor("#2C0000", alpha: 0.25),
				"BtnStrokeAlert1": UIColor("#D34C74"),
				"BtnAlert4": UIColor("#2C0000", alpha: 0.2),
				"BtnStrokeAlert4": UIColor("#D34C74"),
				
				// Slider Button
				"gradSliderCircle-1": UIColor("#FFFFFF"),
				"gradSliderCircle-2": UIColor("#9b9cb4"),
				"gradStrokeSlider-1": UIColor("#3F427E"),
				"gradStrokeSlider-2": UIColor("#464A8B"),
				"BGBtn_Slider": UIColor("#4954ff", alpha: 0.07),
				"BGBtn_SliderFill": UIColor("#6d75f4", alpha: 0.25),
				
				// Gradient
				"gradBgFull-1": UIColor("#1B1C2B"),
				"gradBgFull-2": UIColor("#0E0F17"),
				"gradBgFull-3": UIColor("#0A0A0F"),
				"gradModal-1": UIColor("#1B1C2B"),
				"gradModal-2": UIColor("#1B1C2B"),
				"gradModal-3": UIColor("#161724"),
				"gradTabBar-1": UIColor("#1A1A24"),
				"gradTabBar-2": UIColor("#181820"),
				"gradTabBar_Highlight-1": UIColor("#6663FB", alpha: 0.2),
				"gradTabBar_Highlight-2": UIColor("#546BE5", alpha: 0),
				"gradPanelRows-1": UIColor("#C1C1D9", alpha: 0.1),
				"gradPanelRows-2": UIColor("#D3D3E7", alpha: 0.05),
				"gradPanelRows_Black-1": UIColor("#C0C0CE", alpha: 0.13),
				"gradPanelRows_Black-2": UIColor("#D2D2DB", alpha: 0.1),
				"gradNavBarPanels-1": UIColor("#1D1D2B"),
				"gradNavBarPanels-2": UIColor("#1E1F2E"),
				"gradStroke_NavBarPanels-1": UIColor("#3A3D63", alpha: 1),
				"gradStroke_NavBarPanels-2": UIColor("#5861DE", alpha: 0.51),
				"gradPanelAttributes-1": UIColor("#181826", alpha: 0.5),
				"gradPanelAttributes-2": UIColor("#181826", alpha: 0.2),
				"gradExpBorderTop-1": UIColor("#343AA8"),
				"gradExpBorderTop-2": UIColor("#272D89"),
				"gradExpBorderMiddle-1": UIColor("#272D89"),
				"gradExpBorderMiddle-2": UIColor("#272D89"),
				"gradExpBorderBottom-1": UIColor("#272D89"),
				"gradExpBorderBottom-2": UIColor("#161A5F"),
				"gradGraphToken-1": UIColor("#555CCA", alpha: 0.48),
				"gradGraphToken-2": UIColor("#555CCA", alpha: 0),
				"gradUnconfirmed-1": UIColor("#33334E", alpha: 0.65),
				"gradUnconfirmed-2": UIColor("#323251", alpha: 0.40),
				"gradActivityIcons-1": UIColor("#767CE0", alpha: 0.45),
				"gradActivityIcons-2": UIColor("#8280EC", alpha: 0.75),
				
				// Media player
				"playerKnob": UIColor("#FFFFFF"),
				"playerFill": UIColor("#6D75F4"),
				"playerFillInset": UIColor("#86889D"),
				"playerIconSlider": UIColor("#6D75F4"),
				
				// Background
				"BG0": UIColor("#000000"),
				"BG1": UIColor("#0F0F0F"),
				"BG2": UIColor("#14141D"),
				"BG3": UIColor("#1F1F2B"),
				"BG4": UIColor("#2D2E3F"),
				"BG6": UIColor("#4E5066"),
				"BG8": UIColor("#696A80"),
				"BG10": UIColor("#86889D"),
				"BG12": UIColor("#BCBED4"),
				"BG20": UIColor("#FFFFFF"),
				"BGB0": UIColor("#343994"),
				"BGB2": UIColor("#555CCA"),
				"BGB4": UIColor("#6D75F4"),
				"BGB6": UIColor("#8A90FF"),
				"BGB8": UIColor("#B9BDFF"),
				"BGGood2": UIColor("#097B37"),
				"BGGood4": UIColor("#09AE4B"),
				"BGGood6": UIColor("#39E87F"),
				"BGAlert0": UIColor("#56061E"),
				"BGAlert1": UIColor("#7E1635"),
				"BGAlert2": UIColor("#9F274B"),
				"BGAlert4": UIColor("#D34C74"),
				"BGAlert6": UIColor("#FF759E"),
				"BGB-alt0": UIColor("#9C7205"),
				"BGB-alt2": UIColor("#D69B03"),
				"BGB-alt4": UIColor("#F9C848"),
				"BGB-alt6": UIColor("#FFDB82"),
				"BGMenuContext": UIColor("#2A2B3B"),
				"LineMenuContext": UIColor("#3C3D50"),
				"BGInputs": UIColor("#2D2E3F"),
				"BGPanelExpand": UIColor("#1E1F34", alpha: 0.5),
				"TintGeneral": UIColor("#000000", alpha: 0.75),
				"TintContext": UIColor("#000000", alpha: 0.2),
				"BGQunatity": UIColor("#DFE0F0"),
				"BGSale": UIColor("#6D75F4"),
				"BGLock": UIColor("#D5D6E8"),
				"BGThumbNFT": UIColor("#292828", alpha: 0.5),
				"BGFullNFT": UIColor("#414040", alpha: 0.5),
				"BGSideMenu": UIColor("#23232B"),
				"BGTestState": UIColor("#FF5D29"),
				"BGRecoveryTrans": UIColor("#1C1D23", alpha: 0.65),
				"BGActivityBatch": UIColor("#242B3D", alpha: 0.6),
				"BGMediaOval": UIColor("#000000"),
			],
			others: [:])
	}
	
	public func setup(lightColors: [String: UIColor], darkColors: [String: UIColor], others: [String: ThemeData]) {
		self.themes["Light"] = ThemeData(interfaceStyle: .light, namedColors: lightColors)
		self.themes["Dark"] = ThemeData(interfaceStyle: .dark, namedColors: darkColors)
		self.themes.merge(others) { current, _ in current }
		
		// Swizzle after colors created to avoid issues during setup
		UIColor.swizzleNamedColorInitToAddTheme()
	}
	
	public func updateSystemInterfaceStyle() {
		UIApplication.shared.currentWindow?.overrideUserInterfaceStyle = currentInterfaceStyle()
	}
	
	public func currentInterfaceStyle() -> UIUserInterfaceStyle {
		return self.themes[self.selectedTheme]?.interfaceStyle ?? .dark
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
		return UIColor { _ in
			let dark = ThemeManager.shared.themes["Dark"]?.namedColors[name] ?? .purple
			let light = ThemeManager.shared.themes["Light"]?.namedColors[name] ?? .purple
			
			// Although the callback passes in a trait collection, there are several situations where it always returns the system setting as oppose to the overrided setting
			// Couldn't find the solution, instead just ignore and use the one we are tracking
			// Colors will auto update, but custom views like background gradents will need to be redrawn, and tableviews called reloadData
			return ThemeManager.shared.currentInterfaceStyle() == .dark ? dark : light
		}
	}
	
	@objc func theme_color(named name: String, inBundle: Bundle, compatibleWithTraitCollection: UITraitCollection) -> UIColor? {
		return UIColor { _ in
			let dark = ThemeManager.shared.themes["Dark"]?.namedColors[name] ?? .purple
			let light = ThemeManager.shared.themes["Light"]?.namedColors[name] ?? .purple
			return ThemeManager.shared.currentInterfaceStyle() == .dark ? dark : light
		}
	}
}
