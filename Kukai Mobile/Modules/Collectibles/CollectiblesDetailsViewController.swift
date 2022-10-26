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

class CollectiblesDetailsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout/*, UICollectionViewGridLayoutDelegate*/ {
	
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
		
		/*
		if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = CollectiblesDetailsViewController.verticalLineSpacing
			layout.minimumInteritemSpacing = CollectiblesDetailsViewController.horizontalCellSpacing
			layout.sectionInset = UIEdgeInsets(top: 0, left: CollectiblesDetailsViewController.screenMargin, bottom: 0, right: CollectiblesDetailsViewController.screenMargin)
		}
		*/
		
		
		
		
		
		/*
		let layout = WaterfallLayout()
		layout.delegate = self
		layout.sectionInset = UIEdgeInsets(top: 0, left: CollectiblesDetailsViewController.screenMargin, bottom: 0, right: CollectiblesDetailsViewController.screenMargin)
		layout.minimumLineSpacing = CollectiblesDetailsViewController.verticalLineSpacing
		layout.minimumInteritemSpacing = CollectiblesDetailsViewController.horizontalCellSpacing
		collectionView.collectionViewLayout = layout
		*/
		
		
		
		
		
		
		/*
		let layout = AlignedCollectionViewFlowLayout()
		layout.minimumLineSpacing = CollectiblesDetailsViewController.verticalLineSpacing
		layout.minimumInteritemSpacing = CollectiblesDetailsViewController.horizontalCellSpacing
		layout.sectionInset = UIEdgeInsets(top: 0, left: CollectiblesDetailsViewController.screenMargin, bottom: 0, right: CollectiblesDetailsViewController.screenMargin)
		
		collectionView.collectionViewLayout = layout
		*/
		
		
		
		
		
		
		
		
		/*
		let layout = UICollectionViewGridLayout(numberOfColumns: 2)
		layout.delegate = self
		collectionView.collectionViewLayout = layout
		*/
		
		
		/*
		collectionView.collectionViewLayout = createCompositionalLayout()
		*/
		
		
		/*
		let layout = UICollectionViewFlexibleGridLayout()
		layout.sectionTypes = [.grid, .grid] // TODO: grid to take in number of columns
		layout.delegate = viewModel
		
		collectionView.collectionViewLayout = layout
		*/
		
		
		let layout = CollectibleDetailLayout()
		layout.delegate = viewModel
		collectionView.collectionViewLayout = layout
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
		
		
		
		
		
		
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
	
	
	
	
	
	
	
	func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath:IndexPath) -> CGFloat {
		if indexPath.row <= 1 {
			return 44
		} else if indexPath.row == 2 {
			return 60
		} else if indexPath.row == 3 {
			return 44
		} else if indexPath.row == 4 {
			return 100
		}
		
		return 44
	}
	
	
	
	
	
	
	
	
	
	
	
	func createFullWidthItemSection() -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
		let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
		layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
		
		//let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
		let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [layoutItem])
		//let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, repeatingSubitem: layoutItem, count: 6)
		//let layoutGroup = NSCollectionLayoutGroup.horizontalGroup(with: itemSize, repeatingSubitem: layoutItem, count: 6)
		
		let section = NSCollectionLayoutSection(group: layoutGroup)
		//section.orthogonalScrollingBehavior = .continuous
		
		return section
	}
	
	func createGridItemSection(columns: Int) -> NSCollectionLayoutSection {
		let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
		let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)
		layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
		
		//let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(60))
		//let layoutGroup = NSCollectionLayoutGroup.vertical(layoutSize: layoutGroupSize, subitems: [layoutItem])
		//layoutGroup.interItemSpacing = .fixed(8)
		
		let layoutGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
		let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitem: layoutItem, count: 2)
		layoutGroup.interItemSpacing = .fixed(64)
		
		let section = NSCollectionLayoutSection(group: layoutGroup)
		//section.orthogonalScrollingBehavior = .continuous
		section.interGroupSpacing = 8
		
		return section
	}
	
	func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
		let layout = UICollectionViewCompositionalLayout { [weak self] section, environment in
			if section == 0 {
				return self?.createFullWidthItemSection()
			} else {
				return self?.createGridItemSection(columns: 2)
			}
		}
		
		return layout
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/*
	func collectionView(_ collectionView: UICollectionView, heightForItemAt index: GridIndex, indexPath: IndexPath) -> CGFloat {
		//let columnHeight = self.collectionView(collectionView, heightForRow: index.row)
		//return (index.column + index.row).isMultiple(of: 4) ? columnHeight : columnHeight - 20
		
		let cell = collectionView.cellForItem(at: indexPath)
		let targetSize = CGSize(width: UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2), height: 300)
		let size = cell?.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		print("calling cell height")
		return size?.height ?? 300
	}
	
	func collectionView(_ collectionView: UICollectionView, heightForRow row: Int) -> CGFloat {
		print("calling row height")
		return row.isMultiple(of: 2) ? 100 : 60
	}
	
	func collectionView(_ collectionView: UICollectionView, heightForSupplementaryView kind: UICollectionViewGridLayout.ElementKind, at section: Int) -> CGFloat? {
		return 40
	}
	
	func collectionView(_ collectionView: UICollectionView, alignmentForSection section: Int) -> UICollectionViewGridLayout.Alignment {
		return .top
	}
	
	func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt index: GridIndex, indexPath: IndexPath) -> Int {
		if indexPath.section == 1 && indexPath.row != 0 {
			return 1
		} else {
			return 2
		}
	}
	*/
	
	
	
	
	
	
	
	
	
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

/*
extension CollectiblesDetailsViewController: UICollectionViewFlexibleGridLayoutDelegate {
	
	func heightForContent(atIndex: IndexPath, withContentWidth: CGFloat) -> CGFloat {
		/*let attribute = viewModel.attributes[atIndex.row]
		let size = CGSize(width: withContentWidth, height: 44)
		//let dummyCell = CollectibleDetailAttributeItemCell(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
		
		guard let dummyCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CollectibleDetailAttributeItemCell", for: atIndex) as? CollectibleDetailAttributeItemCell else {
			print("can't find bloody cell")
			return 44
		}
		
		dummyCell.keyLabel.text = attribute.key
		dummyCell.valueLabel.text = attribute.value
		*/
		
		/*
		let defaultSize = CGSize(width: withContentWidth, height: 44)
		let dummyCell = collectionView.cellForItem(at: atIndex)
		let tempEstimatedSize = dummyCell?.contentView.systemLayoutSizeFitting(defaultSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel) ?? defaultSize
		*/
		
		let defaultSize = CGSize(width: withContentWidth, height: 44)
		let dummyCell = collectionView.dataSource?.collectionView(collectionView, cellForItemAt: atIndex)
		let tempEstimatedSize = dummyCell?.contentView.systemLayoutSizeFitting(defaultSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel) ?? defaultSize
		
		
		print("dummyCell: \(dummyCell)")
		print("Supplied contentWidth: \(withContentWidth)")
		print("returning calculated size of: \(tempEstimatedSize)")
		return tempEstimatedSize.height
	}
}
*/

extension CollectiblesDetailsViewController: WaterfallLayoutDelegate {
	
	func collectionViewLayout(for section: Int) -> WaterfallLayout.Layout {
		switch section {
			case 0:
				return .flow(column: 1) // single column flow layout
				
			case 1:
				return .waterfall(column: 2, distributionMethod: .balanced) // three waterfall layout
				
			default:
				return .flow(column: 2)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout: WaterfallLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 44, height: 44)
	}
}
