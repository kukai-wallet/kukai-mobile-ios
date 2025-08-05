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
	private var menuViewController: MenuViewController? = nil
	
	public var selectedToken: Token? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		let navBarMiddleViewWidth = self.view.frame.width - (32 + 44 + 20) // 16 * 2 for left/right gutter, 44 for right buttons, 20 for 10px spacing in between
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: navBarMiddleViewWidth))
		navBarMiddleView.addConstraint(NSLayoutConstraint(item: navBarMiddleView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 28))
		
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		moreButton.addConstraint(NSLayoutConstraint(item: moreButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		viewModel.makeDataSource(withCollectionView: collectionView)
		viewModel.selectedToken = selectedToken
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.delegate = self
		collectionView.collectionViewLayout = createLayout()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView()
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
		
		
		// Setup UI
		MediaProxyService.load(url: selectedToken?.thumbnailURL, to: navBarMiddleImage, withCacheType: .temporary, fallback: UIImage.unknownToken())
		navBarMiddleLabel.text = selectedToken?.name ?? ""
		navBarMiddleView.transform = .init(translationX: 0, y: 44)
		
		menuViewController = viewModel.menuViewControllerForMoreButton(forViewController: self)
		if menuViewController == nil {
			moreButton.isHidden = true
		}
    }
	
	deinit {
		cancellable?.cancel()
		viewModel.cleanup()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isVisible = true
		viewModel.refresh(animate: false)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let padding: CGFloat = 70
		let adjustedOffset = (scrollView.contentOffset.y - padding)
		navBarMiddleView.transform = .init(translationX: 0, y: max(0, (44 - adjustedOffset)))
	}
	
	@IBAction func moreButtonTapped(_ sender: UIButton) {
		menuViewController?.display(attachedTo: sender)
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
