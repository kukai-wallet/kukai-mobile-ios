//
//  PublicBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift

public protocol PublicBakerCellStakeDelegate: AnyObject {
	func stakeButtonTapped(forBaker: TzKTBaker?)
}

public protocol PublicBakerCellInfoDelegate: AnyObject {
	func infoButtonTapped(forBaker: TzKTBaker?)
}

class PublicBakerCell: UITableViewCell {
	
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var splitLabel: UILabel!
	@IBOutlet weak var spaceLabel: UILabel!
	@IBOutlet weak var estRewardsLabel: UILabel!
	
	public var baker: TzKTBaker? = nil
	public weak var stakeDelegate: PublicBakerCellStakeDelegate? = nil
	public weak var infoDelegate: PublicBakerCellInfoDelegate? = nil
	
	@IBAction func stakeButtonTapped(_ sender: Any) {
		self.stakeDelegate?.stakeButtonTapped(forBaker: baker)
	}
	
	@IBAction func infoButtonTapped(_ sender: Any) {
		self.infoDelegate?.infoButtonTapped(forBaker: baker)
	}
}
