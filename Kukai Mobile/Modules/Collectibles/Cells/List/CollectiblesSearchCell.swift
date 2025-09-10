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
	
	private var sortMenu: UIMenu? = nil
	
	func setup(sortMenu: UIMenu) {
		self.sortMenu = sortMenu
		self.sortButton.menu = sortMenu
		self.sortButton.showsMenuAsPrimaryAction = true
		
		searchBar.accessibilityIdentifier = "collectibles-search"
		cancelButton.accessibilityIdentifier = "collectibles-search-cancel"
	}
	
	@IBAction func sortTapped(_ sender: UIButton) {
		//sortMenu?.display(attachedTo: sender)
	}
	
	@IBAction func cancelButtonTapped(_ sender: Any) {
		if searchBar.isFirstResponder {
			searchBar.resignFirstResponder()
			
		} else {
			searchBar.delegate?.textFieldDidEndEditing?(searchBar)
		}
	}
}
