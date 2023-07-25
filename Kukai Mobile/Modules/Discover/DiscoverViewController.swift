//
//  DiscoverViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import Combine

class DiscoverViewController: UIViewController, UITableViewDelegate, DiscoverFeaturedCellDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = DiscoverViewModel()
	private var bag = [AnyCancellable]()
	private var gradient = CAGradientLayer()
	private var featuredTimer: Timer? = nil
	private var featuredCell: DiscoverFeaturedCell? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
		viewModel.menu = MenuViewController(actions: [], header: nil, sourceViewController: self)
		viewModel.makeDataSource(withTableView: tableView)
		viewModel.featuredDelegate = self
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				self?.tableView.reloadData()
				
			}.store(in: &bag)
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			if self?.viewModel.isVisible == true {
				self?.featuredCell?.setupTimer()
			}
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard let url = viewModel.urlForDiscoverItem(atIndexPath: indexPath) else {
			return
		}
		
		featuredTimer?.invalidate()
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
