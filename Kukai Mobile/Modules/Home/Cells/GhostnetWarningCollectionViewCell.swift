//
//  GhostnetWarningCollectionViewCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/04/2023.
//

import UIKit

class GhostnetWarningCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet weak var titleLbl: UILabel!
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		titleLbl.text = "\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName().firstUppercased ?? "")   Test Only"
	}
}
