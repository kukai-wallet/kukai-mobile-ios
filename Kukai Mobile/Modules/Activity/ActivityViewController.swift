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
	private var gradient = CAGradientLayer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
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
					self?.windowError(withTitle: "Error", description: errorString)
					
				case .success:
					self?.refreshControl.endRefreshing()
			}
		}.store(in: &bag)
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			self?.refreshControl.endRefreshing()
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				self?.tableView.reloadData()
				
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.isVisible = true
		viewModel.refresh(animate: false)
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
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView, viewModel.isUnconfirmed(indexPath: indexPath) {
			c.addUnconfirmedGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
			
		} else if let c = cell as? UITableViewCellContainerView, viewModel.expandedIndex != indexPath {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		guard let cell = cell as? UITableViewCellImageDownloading else {
			return
		}
		
		cell.downloadingImageViews().forEach({ $0.kf.cancelDownloadTask() })
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
