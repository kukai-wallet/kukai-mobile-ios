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
		let numberOfRowsInSection0 = collectionView.numberOfItems(inSection: 0)
		if indexPath.section == 0 && indexPath.row == numberOfRowsInSection0-1 {
			viewModel.openOrCloseGroup(forCollectionView: collectionView, atIndexPath: indexPath)
		}
	}
}
