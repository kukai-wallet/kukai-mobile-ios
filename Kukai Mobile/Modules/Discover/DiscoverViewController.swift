//
//  DiscoverViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class DiscoverViewController: UIViewController, UITableViewDelegate, DiscoverFeaturedCellDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = DiscoverViewModel()
	private var bag = [AnyCancellable]()
	private weak var featuredTimer: Timer? = nil
	private weak var featuredCell: DiscoverFeaturedCell? = nil
	private let footer = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 24))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.menu = MenuViewController(actions: [], header: nil, sourceViewController: self)
		viewModel.makeDataSource(withTableView: tableView)
		viewModel.featuredDelegate = self
		
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.tableFooterView = footer
		footer.backgroundColor = .clear
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView()
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}.store(in: &bag)
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			if self?.viewModel.isVisible == true {
				self?.featuredCell?.setupTimer()
			}
		}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let url = viewModel.urlForDiscoverItem(atIndexPath: indexPath) {
			featuredTimer?.invalidate()
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			
		} else if viewModel.isShowMoreOrLess(indexPath: indexPath) {
			viewModel.openOrCloseGroup(forTableView: tableView, atIndexPath: indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let c = cell as? DiscoverCell {
			MediaProxyService.load(url: viewModel.willDisplayImage(forIndexPath: indexPath), to: c.iconView, withCacheType: .temporary, fallback: UIImage.unknownThumb())
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 && indexPath.row == (DependencyManager.shared.currentNetworkType == .mainnet ? 1 : 2) {
			let currentWindowBounds = self.view.window?.windowScene?.keyWindow?.bounds
			return DiscoverFeaturedCell.featuredCellCustomHeight(currentWindowBounds: currentWindowBounds ?? CGRect.zero)
		} else {
			return UITableView.automaticDimension
		}
	}
	
	func innerCellTapped(url: URL?) {
		guard let url = url else {
			return
		}
		
		featuredTimer?.invalidate()
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
	
	func timerSetup(timer: Timer?, sender: DiscoverFeaturedCell) {
		featuredTimer = timer
		featuredCell = sender
	}
}
