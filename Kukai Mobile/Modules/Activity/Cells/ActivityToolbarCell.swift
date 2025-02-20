//
//  ActivityToolbarCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/03/2023.
//

import UIKit

class ActivityToolbarCell: UITableViewCell {
	
	@IBAction func viewInExplorerTapped(_ sender: CustomisableButton) {
		if let tzktAPIURLString = DependencyManager.shared.currentExplorerURL {
			UIApplication.shared.open(tzktAPIURLString.appending(path: DependencyManager.shared.selectedWalletAddress ?? "").appending(path: "operations"))
		}
	}
}
