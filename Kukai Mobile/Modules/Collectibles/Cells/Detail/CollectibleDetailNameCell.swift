//
//  CollectibleDetailNameCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit
import Photos
import KukaiCoreSwift

protocol CollectibleDetailNameCellDelegate: AnyObject {
	func errorMessage(message: String)
	func tokenContractDisplayRequested()
	func shouldDismiss()
}

class CollectibleDetailNameCell: UICollectionViewCell {

	@IBOutlet weak var favouriteButton: CustomisableButton!
	@IBOutlet weak var showcaseButton: CustomisableButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var websiteImageView: UIImageView!
	@IBOutlet weak var websiteButton: UIButton!
	
	private var nft: NFT? = nil
	private var isImage: Bool = false
	private var isFavouritedNft: Bool = false
	private var isHiddenNft: Bool = false
	private var menuVc: MenuViewController? = nil
	
	public weak var delegate: CollectibleDetailNameCellDelegate? = nil
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		// Can't shrink image in IB
		websiteButton.setImage(websiteButton.image(for: .normal)?.resizedImage(size: CGSize(width: 13, height: 13)), for: .normal)
    }
	
	func setup(nft: NFT?, isImage: Bool, isFavourited: Bool, isHidden: Bool, showcaseCount: Int, menuSourceVc: UIViewController) {
		self.nft = nft
		self.isImage = isImage
		self.isFavouritedNft = isFavourited
		self.isHiddenNft = isHidden
		
		
		favouriteButton.accessibilityIdentifier = "button-favourite"
		moreButton.accessibilityIdentifier = "button-more"
		
		setFavState(isFav: isFavourited)
		menuVc = menuForMore(sourceViewController: menuSourceVc)
	}
	
	private func setFavState(isFav: Bool) {
		if isFav {
			favouriteButton.customImage = UIImage(named: "FavoritesOn") ?? UIImage()
			favouriteButton.accessibilityValue = "On"
		} else {
			favouriteButton.customImage = UIImage(named: "FavoritesOff") ?? UIImage()
			favouriteButton.accessibilityValue = "Off"
		}
		
		favouriteButton.updateCustomImage()
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		menuVc?.display(attachedTo: sender)
	}
	
	func menuForMore(sourceViewController: UIViewController) -> MenuViewController {
		guard let nft = nft else {
			return MenuViewController()
		}
		
		var actions: [[UIAction]] = []
		actions.append([])
		let objktCollectionInfo = DependencyManager.shared.objktClient.collections[nft.parentContract]
		
		if isImage {
			actions[0].append(
				UIAction(title: "Save to Photos", image: UIImage(named: "SavetoPhotos"), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft, let imageURL = MediaProxyService.displayURL(forNFT: nft) else {
						return
					}
					
					MediaProxyService.imageCache().retrieveImage(forKey: imageURL.absoluteString, options: []) { [weak self] result in
						guard let res = try? result.get() else {
							self?.delegate?.errorMessage(message: "Unable to locate image in cache, please make sure the image is displayed correctly")
							return
						}
						
						if let img = res.image {
							UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
							
						} else {
							self?.delegate?.errorMessage(message: "Unable to locate image in cache, please make sure the image is displayed correctly")
						}
					}
				})
			)
		}
		
		actions[0].append(UIAction(title: "Token Contract", image: UIImage(named: "About"), identifier: nil, handler: { [weak self] action in
			self?.delegate?.tokenContractDisplayRequested()
		}))
		
		if isHiddenNft {
			actions[0].append(
				UIAction(title: "Unhide Collectible", image: UIImage(named: "HiddenOff"), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft else {
						return
					}
					
					let address = DependencyManager.shared.selectedWalletAddress ?? ""
					if TokenStateService.shared.removeHidden(forAddress: address, nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
						self?.delegate?.shouldDismiss()
						
					} else {
						self?.delegate?.errorMessage(message: "Unable to unhide collectible")
					}
				})
			)
		} else {
			actions[0].append(
				UIAction(title: "Hide Collectible", image: UIImage(named: "HiddenOn"), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft else {
						return
					}
					
					let address = DependencyManager.shared.selectedWalletAddress ?? ""
					if TokenStateService.shared.addHidden(forAddress: address, nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
						self?.delegate?.shouldDismiss()
						
					} else {
						self?.delegate?.errorMessage(message: "Unable to hide collectible")
					}
				})
			)
		}
		
		
		
		// Social section
		if let twitterURL = objktCollectionInfo?.twitterURL() {
			let action = UIAction(title: "Twitter", image: UIImage(named: "Social_Twitter_1color")) { action in
				
				let path = twitterURL.path()
				let pathIndex = path.index(after: path.startIndex)
				let twitterUsername = path.suffix(from: pathIndex)
				if let deeplinkURL = URL(string: "twitter://user?screen_name=\(twitterUsername)"), UIApplication.shared.canOpenURL(deeplinkURL) {
					UIApplication.shared.open(deeplinkURL)
				} else {
					UIApplication.shared.open(twitterURL)
				}
			}
			
			actions.append([action])
		}
		
		
		// Web section
		var webActions: [UIAction] = []
		
		
		let action = UIAction(title: "View Marketplace", image: UIImage(named: "ArrowWeb")) { action in
			if let url = URL(string: "https://objkt.com/collection/\(nft.parentContract)") {
				UIApplication.shared.open(url)
			}
		}
		webActions.append(action)
		
		if let websiteURL = objktCollectionInfo?.websiteURL() {
			let action = UIAction(title: "Collection Website", image: UIImage(named: "ArrowWeb")) { action in
				UIApplication.shared.open(websiteURL)
			}
			
			webActions.append(action)
		}
		actions.append(webActions)
		
		return MenuViewController(actions: actions, header: objktCollectionInfo?.name ?? nft.parentAlias, sourceViewController: sourceViewController)
	}
	
	
	@IBAction func favouriteTapped(_ sender: Any) {
		guard let nft = nft else {
			return
		}
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		
		if isFavouritedNft {
			if TokenStateService.shared.removeFavourite(forAddress: address, nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				favouriteButton.isSelected = false
				isFavouritedNft = false
				setFavState(isFav: false)
				favouriteButton.updateCustomImage()
				
			} else {
				self.delegate?.errorMessage(message: "Unable to unfavorite collectible")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(forAddress: address, nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				favouriteButton.isSelected = true
				isFavouritedNft = true
				setFavState(isFav: true)
				favouriteButton.updateCustomImage()
				
			} else {
				self.delegate?.errorMessage(message: "Unable to favorite collectible")
			}
		}
	}
	
	@IBAction func shareTapped(_ sender: Any) {
		self.delegate?.errorMessage(message: "Share sheet not ready yet")
	}
	
	@IBAction func showcaseTapped(_ sender: Any) {
		self.delegate?.errorMessage(message: "Showcase not ready yet")
	}
}
