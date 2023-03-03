//
//  TokenDetailsButtonsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

protocol TokenDetailsButtonsCellDelegate: AnyObject {
	func favouriteTapped() -> Bool?
	func swapTapped()
}

class TokenDetailsButtonsCell: UITableViewCell {
	
	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var swapButton: CustomisableButton!
	@IBOutlet weak var moreButton: UIButton!
	
	private var buttonData: TokenDetailsButtonData? = nil
	private weak var delegate: TokenDetailsButtonsCellDelegate? = nil
	
	func setup(buttonData: TokenDetailsButtonData, moreMenu: UIMenu?, delegate: TokenDetailsButtonsCellDelegate?) {
		self.buttonData = buttonData
		self.delegate = delegate
		
		favouriteButton.setImage( buttonData.isFavourited ? UIImage(named: "FavoritesOn") : UIImage(named: "FavoritesOff") , for: .normal)
		
		if buttonData.hasMoreButton, let menu = moreMenu {
			moreButton.isHidden = false
			moreButton.menu = menu
			moreButton.showsMenuAsPrimaryAction = true
			
		} else {
			moreButton.isHidden = true
		}
	}
	
	@IBAction func favouriteButtonTapped(_ sender: Any) {
		guard buttonData?.canBeUnFavourited == true else {
			return
		}
		
		if let result = delegate?.favouriteTapped(){
			favouriteButton.setImage( result ? UIImage(named: "FavoritesOn") : UIImage(named: "FavoritesOff") , for: .normal)
		}
	}
	
	@IBAction func swapButtonTapped(_ sender: Any) {
		delegate?.swapTapped()
	}
}
