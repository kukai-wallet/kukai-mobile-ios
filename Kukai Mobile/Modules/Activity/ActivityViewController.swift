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
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	private var firstLoad = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.pullToRefresh(animate: true)
		}), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.refreshControl.endRefreshing()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.refreshControl.endRefreshing()
					(self?.tabBarController as? HomeTabBarController)?.stopActivityAnimationIfNecessary()
			}
		}
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
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		
		if section == viewModel.expandedIndex?.section {
			return 10
			
		} else {
			return 0.1
		}
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		
		if section == viewModel.expandedIndex?.section {
			return 10
			
		} else {
			return 0.1
		}
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		
		if section == viewModel.expandedIndex?.section {
			let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 10))
			view.backgroundColor = .colorNamed("BGActivityBatch")
			return view
			
		} else {
			let view = UIView()
			view.backgroundColor = .clear
			return view
		}
	}
}
