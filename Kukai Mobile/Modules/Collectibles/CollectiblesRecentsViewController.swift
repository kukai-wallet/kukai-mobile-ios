//
//  CollectiblesRecentsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import Combine

class CollectiblesRecentsViewController: UIViewController, UICollectionViewDelegate, CollectiblesViewControllerChild {
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesRecentsViewModel()
	private var cancellable: AnyCancellable?
	
	public weak var delegate: UIViewController? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withCollectionView: collectionView)
		
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
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: false)
	}
	
	private func createLayout() -> UICollectionViewLayout {
		let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.48), heightDimension: .estimated(252))
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(252))
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
}