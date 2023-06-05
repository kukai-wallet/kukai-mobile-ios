//
//  AccountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit
import Combine

class AccountViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = AccountViewModel()
	private var bag = [AnyCancellable]()
	private var refreshControl = UIRefreshControl()
	
	private var coingeckservice: CoinGeckoService? = nil
	private var gradient = CAGradientLayer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
		viewModel.balancesMenuVC = menuVCForBalancesMore()
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
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.refreshControl.endRefreshing()
					(self?.tabBarController as? HomeTabBarController)?.stopActivityAnimationIfNecessary()
			}
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				
				self?.tableView.visibleCells.forEach({ ($0 as? UITableViewCellThemeUpdated)?.themeUpdated() })
				
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isPresentedForSelectingToken = (self.parent != nil && self.tabBarController == nil)
		viewModel.isVisible = true
		viewModel.refresh(animate: false)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		viewModel.isVisible = false
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let token = viewModel.token(atIndexPath: indexPath) {
			TransactionService.shared.resetState()
			TransactionService.shared.sendData.chosenToken = token
			TransactionService.shared.sendData.chosenNFT = nil
			self.performSegue(withIdentifier: "details", sender: self)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func menuVCForBalancesMore() -> MenuViewController {
		let actions: [UIAction] = [
			UIAction(title: "Favourites", image: UIImage(named: "FavoritesOn")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "favourites", sender: nil)
			}),
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "HiddenOff")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "hidden", sender: nil)
			}),
		]
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: self)
	}
}
