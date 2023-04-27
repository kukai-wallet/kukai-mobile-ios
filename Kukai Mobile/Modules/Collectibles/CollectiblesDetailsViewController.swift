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
	
	@IBOutlet weak var collectionView: UICollectionView!
	
	private let viewModel = CollectiblesDetailsViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		guard let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		viewModel.nft = nft
		viewModel.sendTarget = self
		viewModel.sendAction = #selector(self.sendTapped)
		viewModel.actionsDelegate = self
		viewModel.menuSourceController = self
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
		
		self.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		MediaProxyService.imageCache().removeImage(forKey: "https://static.tcinfra.net/media/small/ipfs/QmeaXkDRAKKAm52xUoiGsY91yi3xZrkwErKatv4SqApzu4") {
			print("cleared")
		}
		
		MediaProxyService.imageCache().removeImage(forKey: "https://static.tcinfra.net/media/small/ipfs/QmeX133ZNZShmyPEdkEwDGP9kogMp8fXeJKPeMQnyKcWvx") {
			print("cleared")
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? TokenContractViewController {
			vc.setup(tokenId: viewModel.nft?.tokenId.description ?? "0", contractAddress: viewModel.nft?.parentContract ?? "")
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if viewModel.attributes.count == 0 {
			return
		}
		
		let numberOfRowsFirstSection = collectionView.numberOfItems(inSection: 0)
		if indexPath.section == 0 && indexPath.row == numberOfRowsFirstSection-1 {
			viewModel.openOrCloseGroup(forCollectionView: collectionView, atIndexPath: indexPath)
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	@objc func sendTapped() {
		TransactionService.shared.sendData.chosenNFT = viewModel.nft
		TransactionService.shared.sendData.chosenAmount = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0)
		self.performSegue(withIdentifier: "send", sender: nil)
	}
}

extension CollectiblesDetailsViewController: CollectibleDetailNameCellDelegate {
	
	func errorMessage(message: String) {
		self.alert(errorWithMessage: message)
	}
	
	func tokenContractDisplayRequested() {
		self.performSegue(withIdentifier: "tokenContract", sender: nil)
	}
	
	func shouldDismiss() {
		self.dismiss(animated: true)
	}
}
