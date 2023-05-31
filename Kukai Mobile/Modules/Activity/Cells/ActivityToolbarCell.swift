//
//  ActivityToolbarCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/03/2023.
//

import UIKit

class ActivityToolbarCell: UITableViewCell {
	
	@IBAction func viewInExplorerTapped(_ sender: CustomisableButton) {
		let tzktAPIURLString = DependencyManager.shared.tezosClientConfig.tzktURL.absoluteString
		let stripAPI = tzktAPIURLString.replacingOccurrences(of: "api.", with: "")
		
		if let websiteURL = URL(string: stripAPI)?.appending(path: DependencyManager.shared.selectedWalletAddress ?? "").appending(path: "operations") {
			UIApplication.shared.open(websiteURL)
		}
	}
}
