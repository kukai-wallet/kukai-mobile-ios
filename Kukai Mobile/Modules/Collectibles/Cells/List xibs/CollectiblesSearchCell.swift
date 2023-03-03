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
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var buttonsStackView: UIStackView!
	
	private var sortMenu: MenuViewController? = nil
	private var moreMenu: MenuViewController? = nil
	
	func setup(sortMenu: MenuViewController, moreMenu: MenuViewController) {
		self.sortMenu = sortMenu
		self.moreMenu = moreMenu
	}
	
	@IBAction func sortTapped(_ sender: UIButton) {
		sortMenu?.display(attachedTo: sender)
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		moreMenu?.display(attachedTo: sender)
	}
}
