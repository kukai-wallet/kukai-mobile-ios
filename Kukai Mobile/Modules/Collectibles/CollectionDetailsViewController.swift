//
//  CollectionDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift
import Combine

class CollectionDetailsViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
	
	@IBOutlet weak var navBarMiddleView: UIView!
	@IBOutlet weak var navBarMiddleImage: UIImageView!
	@IBOutlet weak var navBarMiddleLabel: UILabel!
	@IBOutlet weak var moreButton: CustomisableButton!
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectionDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	public var selectedToken: Token? = nil
	public var externalImage: UIImage? = nil
	public var externalName: String? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		let navBarMiddleViewWidth = self.view.frame.width - (32 + 44 + 20) // 16 * 2 for left/right gutter, 44 for right buttons, 20 for 10px spacing in between
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: navBarMiddleViewWidth))
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28))
		
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		viewModel.makeDataSource(withCollectionView: collectionView)
		viewModel.selectedToken = selectedToken
		viewModel.externalName = externalName
		viewModel.externalImage = externalImage
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		collectionView.collectionViewLayout = createLayout()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					print("loading")
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
		
		
		// Setup UI
		if let image = externalImage {
			navBarMiddleImage.image = image
			
		} else {
			MediaProxyService.load(url: selectedToken?.thumbnailURL, to: navBarMiddleImage, withCacheType: .temporary, fallback: UIImage.unknownToken())
		}
		
		navBarMiddleLabel.text = externalName ?? selectedToken?.name
		navBarMiddleView.transform = .init(translationX: 0, y: 44)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let padding: CGFloat = 70
		let adjustedOffset = (scrollView.contentOffset.y - padding)
		navBarMiddleView.transform = .init(translationX: 0, y: max(0, (44 - adjustedOffset)))
	}
	
	@IBAction func moreButtonTapped(_ sender: Any) {
	}
	
	
	private func createLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			
			if sectionIndex == 0 {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(130))
				let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 16
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
				return section
				
			} else {
				let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(204))
				let item = NSCollectionLayoutItem(layoutSize: itemSize)
				
				let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(204))
				let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
				
				group.interItemSpacing = .fixed(18)
				
				let section = NSCollectionLayoutSection (group: group)
				section.interGroupSpacing = 16
				section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
				return section
			}
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			return
			
		} else if let obj = viewModel.nft(forIndexPath: indexPath) {
			TransactionService.shared.sendData.chosenNFT = obj
			self.performSegue(withIdentifier: "detail", sender: obj)
		}
	}
}
