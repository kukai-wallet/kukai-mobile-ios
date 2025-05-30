//
//  ActivityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit
import Combine

class ActivityViewController: UIViewController, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = ActivityViewModel()
	private var bag = [AnyCancellable]()
	private var refreshControl = UIRefreshControl()
	private var firstLoad = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.pullToRefresh(animate: true)
		}), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.refreshControl.endRefreshing()
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					self?.refreshControl.endRefreshing()
			}
		}.store(in: &bag)
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			self?.refreshControl.endRefreshing()
		}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
		viewModel.cleanup()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.isVisible = true
		
		let pendingAddresses = DependencyManager.shared.activityService.addressesWithPendingOperation
		if let selectedAddress = DependencyManager.shared.selectedWalletAddress, !pendingAddresses.contains([selectedAddress]) {
			(self.tabBarController as? HomeTabBarController)?.stopActivityAnimationIfNecessary()
		}
		viewModel.refresh(animate: false)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		AccountViewModel.reconnectAccountActivityListenerIfNeeded()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.row == 0 {
			viewModel.openOrCloseGroup(forTableView: tableView, atIndexPath: indexPath)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.sd_cancelCurrentImageLoad() })
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let view = UIView()
		view.backgroundColor = .clear
		return view
	}
}
