//
//  SideMenuAboutCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2023.
//

import UIKit

class SideMenuAboutCell: UITableViewCell {
	
	@IBOutlet weak var versionLabel: UILabel!
	@IBOutlet weak var twitterButton: CustomisableButton!
	@IBOutlet weak var discordButton: CustomisableButton!
	@IBOutlet weak var telegramButton: CustomisableButton!
	
	func setup() {
		let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
		let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
		
		versionLabel.text = "v\(version) (\(build))"
		
		twitterButton.customButtonType = .secondary
		twitterButton.accessibilityIdentifier = "side-menu-twitter"
		
		discordButton.customButtonType = .secondary
		discordButton.accessibilityIdentifier = "side-menu-discord"
		
		telegramButton.customButtonType = .secondary
		telegramButton.accessibilityIdentifier = "side-menu-telegram"
	}
	
	@IBAction func twitterButtonTapped(_ sender: Any) {
		guard let native = URL(string: "twitter://user?screen_name=KukaiWallet"), let web = URL(string: "https://twitter.com/KukaiWallet/") else {
			return
		}
		
		if UIApplication.shared.canOpenURL(native) {
			UIApplication.shared.open(native)
			
		} else {
			UIApplication.shared.open(web)
		}
	}
	
	@IBAction func discordButtonTapped(_ sender: Any) {
		guard let native = URL(string: "discord://R454ym4M"), let web = URL(string: "https://discord.gg/R454ym4M") else {
			return
		}
		
		if UIApplication.shared.canOpenURL(native) {
			UIApplication.shared.open(native)
			
		} else {
			UIApplication.shared.open(web)
		}
	}
	
	@IBAction func telegramButtonTapped(_ sender: Any) {
		guard let native = URL(string: "tg://resolve?domain=KukaiWallet"), let web = URL(string: "https://t.me/KukaiWallet") else {
			return
		}
		
		if UIApplication.shared.canOpenURL(native) {
			UIApplication.shared.open(native)
			
		} else {
			UIApplication.shared.open(web)
		}
	}
	
	@IBAction func termsAndConditionsTapped(_ sender: Any) {
		guard let url = URL(string: "https://wallet.kukai.app/terms-of-use") else {
			return
		}
		
		UIApplication.shared.open(url)
	}
	
	@IBAction func privacyPolicyTapped(_ sender: Any) {
		guard let url = URL(string: "https://wallet.kukai.app/privacy-policy") else {
			return
		}
		
		UIApplication.shared.open(url)
	}
}
