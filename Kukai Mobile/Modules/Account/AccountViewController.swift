//
//  AccountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit
import Combine

class AccountViewController: UIViewController, UITableViewDelegate, EstimatedTotalCellDelegate {
	
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
		viewModel.estimatedTotalCellDelegate = self
		viewModel.tableViewButtonDelegate = self
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
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				self?.tableView.reloadData()
				
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.isPresentedForSelectingToken = (self.parent != nil && self.tabBarController == nil)
		viewModel.isVisible = true
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
		
		if let token = viewModel.token(atIndexPath: indexPath) {
			TransactionService.shared.resetAllState()
			TransactionService.shared.sendData.chosenToken = token
			TransactionService.shared.sendData.chosenNFT = nil
			self.performSegue(withIdentifier: "details", sender: self)
			
		} else if viewModel.isBackUpCell(atIndexPath: indexPath) {
			self.performSegue(withIdentifier: "recover", sender: self)
			
		} else if viewModel.isUpdateWarningCell(atIndexPath: indexPath) {
			UIApplication.shared.open(AppUpdateService.appStoreURL)
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
		
		cell.downloadingImageViews().forEach({ $0.sd_cancelCurrentImageLoad() })
	}
	
	func menuVCForBalancesMore() -> MenuViewController {
		let actions: [UIAction] = [
			UIAction(title: "Favorites", image: UIImage(named: "FavoritesOn")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "favourites", sender: nil)
			}),
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "HiddenOff")?.resizedImage(size: CGSize(width: 26, height: 26)), identifier: nil, handler: { [weak self] action in
				self?.performSegue(withIdentifier: "hidden", sender: nil)
			}),
		]
		
		return MenuViewController(actions: [actions], header: nil, sourceViewController: self)
	}
	
	func totalEstiamtedInfoTapped() {
		self.alert(withTitle: "Total Estimated", andMessage: "Info Text")
	}
}

extension AccountViewController: UITableViewCellButtonDelegate {
	
	func tableViewCellButtonTapped(sender: UIButton) {
		switch sender.accessibilityIdentifier {
			case AccountViewModel.accessibilityIdentifiers.onramp:
				if DependencyManager.shared.currentNetworkType == .testnet {
					UIApplication.shared.open(DependencyManager.ghostnetFaucetLink)
					
				} else {
					self.performSegue(withIdentifier: "onramp", sender: nil)
				}
			
			case AccountViewModel.accessibilityIdentifiers.discover:
				(self.tabBarController as? HomeTabBarController)?.manuallySetSlectedTab(toIndex: 3)
				
			case AccountViewModel.accessibilityIdentifiers.qr:
				(self.tabBarController as? HomeTabBarController)?.performSegue(withIdentifier: "side-menu-show-qr", sender: nil)
				
			case AccountViewModel.accessibilityIdentifiers.copy:
				let address = DependencyManager.shared.selectedWalletAddress ?? ""
				
				Toast.shared.show(withMessage: "\(address.truncateTezosAddress()) copied!", attachedTo: sender)
				UIPasteboard.general.string = address
				
			default:
				self.windowError(withTitle: "error".localized(), description: "error-unsupport-action".localized())
		}
	}
}
