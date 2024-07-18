//
//  CollectiblesFavouritesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import Combine
import KukaiCoreSwift

class CollectiblesFavouritesViewController: UIViewController, UICollectionViewDelegate, CollectiblesViewControllerChild {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesFavouritesViewModel()
	private var bag = [AnyCancellable]()
	
	public weak var delegate: UIViewController? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withCollectionView: collectionView)
		
		collectionView.dataSource = viewModel.dataSource
		collectionView.accessibilityIdentifier = "collectibles-fav-view"
		collectionView.delegate = self
		collectionView.collectionViewLayout = createLayout()
		
		viewModel.$state.sink { [weak self] state in
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
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.collectionView.reloadData()
				
			}.store(in: &bag)
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
	
	func needsRefreshFromParent() {
		viewModel.refresh(animate: true)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(220))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(220))
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
			
			group.interItemSpacing = .fixed(18)
			
			let section = NSCollectionLayoutSection (group: group)
			section.interGroupSpacing = 24
			section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
			return section
		}
		
		let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
		return layout
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if let obj = viewModel.nft(forIndexPath: indexPath) {
			TransactionService.shared.sendData.chosenNFT = obj
			delegate?.performSegue(withIdentifier: "detail", sender: obj)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let c = cell as? CollectiblesCollectionLargeCell, let url = viewModel.willDisplayImages(forIndexPath: indexPath).first {
			MediaProxyService.load(url: url, to: c.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.sd_cancelCurrentImageLoad() })
	}
}
