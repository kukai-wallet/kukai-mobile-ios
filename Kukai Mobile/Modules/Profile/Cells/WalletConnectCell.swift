//
//  WalletConnectCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit

protocol WalletConnectCellProtocol: AnyObject {
	func deleteTapped(forRow: Int)
}

class WalletConnectCell: UITableViewCell {
	
	@IBOutlet weak var nameLbl: UILabel!
	@IBOutlet weak var serverLbl: UILabel!
	
	public var row: Int = 0
	public weak var delegate: WalletConnectCellProtocol? = nil
	
	@IBAction func deleteTapped(_ sender: Any) {
		delegate?.deleteTapped(forRow: row)
	}
}
