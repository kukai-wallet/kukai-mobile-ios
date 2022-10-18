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

class CollectiblesDetailsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	
	public static let screenMargin: CGFloat = 16
	public static let verticalLineSpacing: CGFloat = 4
	public static let horizontalCellSpacing: CGFloat = 4
	
	@IBOutlet weak var onSaleButton: UIButton!
	@IBOutlet weak var onSaleLabel: UILabel!
	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		viewModel.nft = nft
		viewModel.makeDataSource(withCollectionView: collectionView)
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		
		if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = CollectiblesDetailsViewController.verticalLineSpacing
			layout.minimumInteritemSpacing = CollectiblesDetailsViewController.horizontalCellSpacing
			layout.sectionInset = UIEdgeInsets(top: 0, left: CollectiblesDetailsViewController.screenMargin, bottom: 0, right: CollectiblesDetailsViewController.screenMargin)
		}
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.section == 1 && indexPath.row == 0 {
			viewModel.openOrCloseGroup(forCollectionView: collectionView, atIndexPath: indexPath)
		}
	}
	
	
	/*
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
	*/
}
