//
//  AppUpdateService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/10/2023.
//

import Foundation

public struct MobileVersionData: Codable {
	let ios: MobileVersioniOS
}

public struct MobileVersioniOS: Codable {
	let required: String
	let recommended: String
}

public class AppUpdateService {
	
	// mt = meida type. 8 = mobile application. See: https://stackoverflow.com/questions/1781427/what-is-mt-8-in-itunes-links-for-the-app-store
	public static let appStoreURL = URL(string: "https://apps.apple.com/ie/app/numbers/id1576499860?mt=8")!
	
	public static let shared = AppUpdateService()
	
	public var requiredVersion: String? = nil
	public var isRequiredUpdate = false
	public var recommendedVersion: String? = nil
	public var isRecommendedUpdate = false
	
	private init() {}
	
	public func processVersionData(data: MobileVersionData) {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
		let currentAppVersionString = "\(version).\(build)"
		
	}
}
