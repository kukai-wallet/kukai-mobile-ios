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
	@IBOutlet weak var cancelButton: UIButton!
	
	private var sortMenu: MenuViewController? = nil
	
	func setup(sortMenu: MenuViewController) {
		self.sortMenu = sortMenu
		
		searchBar.accessibilityIdentifier = "collectibles-search"
		cancelButton.accessibilityIdentifier = "collectibles-search-cancel"
	}
	
	@IBAction func sortTapped(_ sender: UIButton) {
		sortMenu?.display(attachedTo: sender)
	}
	
	@IBAction func cancelButtonTapped(_ sender: Any) {
		searchBar.delegate?.textFieldDidEndEditing?(searchBar)
	}
}
