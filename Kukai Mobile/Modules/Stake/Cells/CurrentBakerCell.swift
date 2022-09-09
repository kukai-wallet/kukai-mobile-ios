//
//  CurrentBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift

class CurrentBakerCell: UITableViewCell {

	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var splitLabel: UILabel!
	@IBOutlet weak var spaceLabel: UILabel!
	@IBOutlet weak var estRewardsLabel: UILabel!
	
	public var baker: TzKTBaker? = nil
	public weak var infoDelegate: PublicBakerCellInfoDelegate? = nil
	
	@IBAction func infoButtonTapped(_ sender: Any) {
		self.infoDelegate?.infoButtonTapped(forBaker: baker)
	}
}
