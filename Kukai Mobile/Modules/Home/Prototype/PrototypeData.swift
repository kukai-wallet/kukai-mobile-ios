//
//  PrototypeData.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import Foundation

public class PrototypeData {
	
	public static let shared = PrototypeData()
	
	public enum PrototypeSelection {
		case token
		case nft
	}
	
	public var selected: PrototypeSelection = .token
	public var selectedIndex = 0
	public var selectedNFT = 0
	public var selectedOption = 0
	
	private init () {}
	
	public func reset() {
		selected = .token
		selectedIndex = 0
		selectedNFT = 0
		selectedOption = 0
	}
}
