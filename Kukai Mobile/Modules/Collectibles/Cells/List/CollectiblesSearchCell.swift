//
//  CollectiblesSearchCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/12/2022.
//

import UIKit

class CollectiblesSearchCell: UICollectionViewCell {

	@IBOutlet weak var searchBar: ValidatorTextField!
	@IBOutlet weak var sortButton: CustomisableButton!
	
	private var sortMenu: MenuViewController? = nil
	
	func setup(sortMenu: MenuViewController) {
		self.sortMenu = sortMenu
	}
	
	@IBAction func sortTapped(_ sender: UIButton) {
		sortMenu?.display(attachedTo: sender)
	}
}
