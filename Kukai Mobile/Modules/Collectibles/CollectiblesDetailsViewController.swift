//
//  CollectiblesDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import AVKit
import Combine

class CollectiblesDetailsViewController: UIViewController, UICollectionViewDelegate {
	
	@IBOutlet weak var favouriteButtonBarItem: UIBarButtonItem!
	@IBOutlet weak var favouriteButton: CustomisableButton!
	@IBOutlet weak var moreButtonBarItem: UIBarButtonItem!
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesDetailsViewModel()
	private var cancellable: AnyCancellable?
	private var menu: MenuViewController? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		favouriteButton.accessibilityIdentifier = "button-favourite"
		moreButton.accessibilityIdentifier = "button-more"
		
		guard let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		viewModel.nft = nft
		viewModel.sendDelegate = self
		viewModel.makeDataSource(withCollectionView: collectionView)
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		
		
		let layout = CollectibleDetailLayout()
		layout.delegate = viewModel
		collectionView.collectionViewLayout = layout
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					self?.setFavState(isFav: self?.viewModel.isFavourited ?? false)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? TokenContractViewController {
			vc.setup(tokenId: viewModel.nft?.tokenId.description ?? "0", contractAddress: viewModel.nft?.parentContract ?? "")
			
		} else if let vc = segue.destination as? CollectibleAttributeDetailViewController, let item = sender as? AttributeItem {
			vc.attributeItem = item
		}
	}
	
	@IBAction func favouriteButtonTapped(_ sender: CustomisableButton) {
		guard let nft = viewModel.nft else {
			return
		}
		
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		
		if viewModel.isFavourited {
			if TokenStateService.shared.removeFavourite(forAddress: address, nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.isFavourited = false
				setFavState(isFav: false)
				favouriteButton.updateCustomImage()
				
			} else {
				self.windowError(withTitle: "error".localized(), description: "error-cant-unfav".localized())
			}
			
		} else {
			if TokenStateService.shared.addFavourite(forAddress: address, nft: nft) {
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				viewModel.isFavourited = true
				setFavState(isFav: true)
				favouriteButton.updateCustomImage()
				
			} else {
				self.windowError(withTitle: "error".localized(), description: "error-cant-fav".localized())
			}
		}
	}
	
	@IBAction func moreButtonTapped(_ sender: CustomisableButton) {
		menu = moreMenu()
		menu?.display(attachedTo: sender)
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if viewModel.attributes.count == 0 {
			return
		}
		
		let numberOfRowsFirstSection = collectionView.numberOfItems(inSection: 0)
		if indexPath.section == 0 && indexPath.row == numberOfRowsFirstSection-1 {
			viewModel.openOrCloseGroup(forCollectionView: collectionView, atIndexPath: indexPath)
			
		} else if indexPath.section == 1 {
			let attribute = viewModel.attributeFor(indexPath: indexPath)
			self.performSegue(withIdentifier: "attributeDetail", sender: attribute)
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.dismiss(animated: true)
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
	
	func moreMenu() -> MenuViewController {
		guard let nft = viewModel.nft else {
			return MenuViewController()
		}
		
		var actions: [[UIAction]] = []
		actions.append([])
		let objktCollectionInfo = DependencyManager.shared.objktClient.collections[nft.parentContract]
		
		if viewModel.mediaContent.isImage {
			actions[0].append(
				UIAction(title: "Save to Photos", image: UIImage(named: "SavetoPhotos"), identifier: nil, handler: { [weak self] action in
					guard let imageURL = MediaProxyService.largeURL(forNFT: nft) else {
						return
					}
					
					if let image = MediaProxyService.imageCache(forType: .temporary).imageFromCache(forKey: imageURL.absoluteString) {
						UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
					} else {
						self?.windowError(withTitle: "error".localized(), description: "error-image-not-in-cahce".localized())
					}
				})
			)
		}
		
		actions[0].append(UIAction(title: "Token Contract", image: UIImage(named: "About"), identifier: nil, handler: { [weak self] action in
			self?.performSegue(withIdentifier: "tokenContract", sender: nil)
		}))
		
		if viewModel.isHidden {
			actions[0].append(
				UIAction(title: "Unhide Collectible", image: UIImage(named: "HiddenOff"), identifier: nil, handler: { [weak self] action in
					let address = DependencyManager.shared.selectedWalletAddress ?? ""
					if TokenStateService.shared.removeHidden(forAddress: address, nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
						self?.navigationController?.popViewController(animated: true)
						
					} else {
						self?.windowError(withTitle: "error".localized(), description: "error-unhide-token".localized())
					}
				})
			)
		} else {
			actions[0].append(
				UIAction(title: "Hide Collectible", image: UIImage(named: "HiddenOn"), identifier: nil, handler: { [weak self] action in
					let address = DependencyManager.shared.selectedWalletAddress ?? ""
					if TokenStateService.shared.addHidden(forAddress: address, nft: nft) {
						DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
						self?.navigationController?.popViewController(animated: true)
						
					} else {
						self?.windowError(withTitle: "error".localized(), description: "error-hide-token".localized())
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
		
		return MenuViewController(actions: actions, header: objktCollectionInfo?.name ?? nft.parentAlias, sourceViewController: self)
	}
}

extension CollectiblesDetailsViewController: CollectibleDetailSendDelegate {
	
	func sendTapped() {
		TransactionService.shared.sendData.chosenNFT = viewModel.nft
		TransactionService.shared.sendData.chosenAmount = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0)
		self.performSegue(withIdentifier: "send", sender: nil)
	}
}
