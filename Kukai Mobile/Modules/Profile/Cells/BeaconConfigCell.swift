//
//  BeaconConfigCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 10/05/2022.
//

import UIKit

protocol BeaconConfigCellProtocol: AnyObject {
	func deleteTapped(forRow: Int)
}

class BeaconConfigCell: UITableViewCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var fieldNameLabel: UILabel!
	@IBOutlet weak var fieldValueLabel: UILabel!
	
	public var row: Int = 0
	public weak var delegate: BeaconConfigCellProtocol? = nil
	
	@IBAction func deleteTapped(_ sender: Any) {
		delegate?.deleteTapped(forRow: row)
	}
}
