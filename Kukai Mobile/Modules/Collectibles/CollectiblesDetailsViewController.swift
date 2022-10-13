//
//  CollectiblesDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/03/2022.
//

import UIKit
import KukaiCoreSwift
import AVKit

class CollectiblesDetailsViewController: UIViewController {
	
	@IBOutlet weak var imageDisplayView: UIImageView!
	@IBOutlet weak var playerContainerView: UIView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	private let viewModel = CollectiblesDetailsViewModel()
	private var playerController: AVPlayerViewController? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		imageDisplayView.isHidden = true
		playerContainerView.isHidden = true
		activityIndicator.startAnimating()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		viewModel.loadOfflineData(nft: nft)
		
		self.nameLabel.text = viewModel.name
		self.descriptionLabel.text = viewModel.description
		
		viewModel.getMediaType(nft: nft) { [weak self] result in
			switch result {
				case .success(let mediaType):
					
					DispatchQueue.main.async {
						self?.activityIndicator.stopAnimating()
						self?.activityIndicator.isHidden = true
						
						if mediaType == .image {
							self?.loadImage(forNft: nft)
							
						} else {
							self?.loadAV(forNFT: nft)
						}
					}
					
				case .failure(let error):
					self?.alert(errorWithMessage: "\(error)")
			}
		}
	}
	
	func loadImage(forNft: NFT) {
		self.imageDisplayView.isHidden = false
		MediaProxyService.load(url: forNft.artifactURL, to: self.imageDisplayView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
	}
	
	func loadAV(forNFT: NFT) {
		guard let url = forNFT.artifactURL else {
			print("Not NFT url found")
			return
		}
		
		self.playerContainerView.isHidden = false
		let player = AVPlayer(url: url)
		self.playerController?.player = player
	}
	
	@IBAction func sendTapped(_ sender: Any) {
		let homeTabController = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? HomeTabBarController
		
		self.dismiss(animated: true) {
			homeTabController?.sendButtonTapped(self)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "avplayer", let vc = segue.destination as? AVPlayerViewController {
			self.playerController = vc
		}
	}
}
