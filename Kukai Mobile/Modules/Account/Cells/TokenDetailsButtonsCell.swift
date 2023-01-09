//
//  TokenDetailsButtonsCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

protocol TokenDetailsButtonsCellDelegate: AnyObject {
	func favouriteTapped() -> Bool?
	func buyTapped()
}

class TokenDetailsButtonsCell: UITableViewCell {
	
	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var buyButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	
	private var buttonData: TokenDetailsButtonData? = nil
	private weak var delegate: TokenDetailsButtonsCellDelegate? = nil
	
	func setup(buttonData: TokenDetailsButtonData, moreMenu: UIMenu?, delegate: TokenDetailsButtonsCellDelegate?) {
		self.buttonData = buttonData
		self.delegate = delegate
		
		favouriteButton.setImage( buttonData.isFavourited ? UIImage(named: "Favorites") : UIImage(named: "FavoritesOff") , for: .normal)
		buyButton.isHidden = !buttonData.canBePurchased
		
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
			favouriteButton.setImage( result ? UIImage(named: "Favorites") : UIImage(named: "FavoritesOff") , for: .normal)
		}
	}
	
	@IBAction func buyTapped(_ sender: Any) {
		delegate?.buyTapped()
	}
}
