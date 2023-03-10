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

	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var websiteImageView: UIImageView!
	@IBOutlet weak var websiteButton: UIButton!
	@IBOutlet weak var showcaseLabel: UILabel!
	
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
		
		favouriteButton.isSelected = isFavourited
		menuVc = menuForMore(sourceViewController: menuSourceVc)
		
		if showcaseCount > 0 {
			showcaseLabel.text = "Showcase (\(showcaseCount))"
		} else {
			showcaseLabel.isHidden = true
		}
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		menuVc?.display(attachedTo: sender)
	}
	
	func menuForMore(sourceViewController: UIViewController) -> MenuViewController {
		var actions: [UIAction] = []
		
		
		if isImage {
			actions.append(
				UIAction(title: "Save to Photos", image: UIImage(named: "SavetoPhotos")?.resizedImage(size: CGSize(width: 21, height: 24)), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft, let imageURL = MediaProxyService.displayURL(forNFT: nft) else {
						return
					}
					
					MediaProxyService.temporaryImageCache().retrieveImage(forKey: imageURL.absoluteString, options: []) { [weak self] result in
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
		
		actions.append(UIAction(title: "Token Contract", image: UIImage(named: "About")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
			self?.delegate?.tokenContractDisplayRequested()
		}))
		
		if isHiddenNft {
			actions.append(
				UIAction(title: "Unhide Collectible", image: UIImage(named: "HiddenOff")?.resizedImage(size: CGSize(width: 24, height: 17)), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft else {
						return
					}
					
					if TokenStateService.shared.removeHidden(nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates()
						DependencyManager.shared.accountBalancesDidUpdate = true
						self?.delegate?.shouldDismiss()
						
					} else {
						self?.delegate?.errorMessage(message: "Unable to unhide collectible")
					}
				})
			)
		} else {
			actions.append(
				UIAction(title: "Hide Collectible", image: UIImage(named: "HiddenOn")?.resizedImage(size: CGSize(width: 24, height: 19)), identifier: nil, handler: { [weak self] action in
					guard let nft = self?.nft else {
						return
					}
					
					if TokenStateService.shared.addHidden(nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates()
						DependencyManager.shared.accountBalancesDidUpdate = true
						self?.delegate?.shouldDismiss()
						
					} else {
						self?.delegate?.errorMessage(message: "Unable to hide collectible")
					}
				})
			)
		}
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: sourceViewController)
	}
	
	
	@IBAction func favouriteTapped(_ sender: Any) {
		guard let nft = nft else {
			return
		}
		
		if isFavouritedNft {
			if TokenStateService.shared.removeFavourite(nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				favouriteButton.isSelected = false
				isFavouritedNft = false
				
			} else {
				self.delegate?.errorMessage(message: "Unable to unfavourite collectible")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				favouriteButton.isSelected = true
				isFavouritedNft = true
				
			} else {
				self.delegate?.errorMessage(message: "Unable to favourite collectible")
			}
		}
	}
	
	@IBAction func shareTapped(_ sender: Any) {
		self.delegate?.errorMessage(message: "Share sheet not ready yet")
	}
}
