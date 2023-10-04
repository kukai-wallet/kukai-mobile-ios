//
//  HiddenCollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/12/2022.
//

import UIKit
import Combine
import Kingfisher

class HiddenCollectiblesViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = HiddenCollectiblesViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "Error", description: errorString)
					
				case .success:
					let _ = ""
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let nft = viewModel.nft(atIndexPath: indexPath) {
			TransactionService.shared.resetAllState()
			TransactionService.shared.sendData.chosenToken = nil
			TransactionService.shared.sendData.chosenNFT = nft
			(self.parent as? HiddenTokensMainViewController)?.openCollectibleDetails()
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.kf.cancelDownloadTask() })
	}
}
