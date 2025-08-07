//
//  GhostnetWarningCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/04/2023.
//

import UIKit

public struct GhostnetWarningCellObj: Hashable {
	public let id = UUID()
}

class GhostnetWarningCell: UITableViewCell {
	
	@IBOutlet weak var titleLbl: UILabel!
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		//titleLbl.text = "\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName().firstUppercased ?? "")   Test Only"
		titleLbl.text = "\(DependencyManager.NetworkManagement.currentNetworkDisplayName())   Test Only"
	}
}
