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
	@IBOutlet weak var balancesMoreButton: UIButton!
	
	private let viewModel = AccountViewModel()
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	
	private var coingeckservice: CoinGeckoService? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//self.view.backgroundColor = .white
		self.view.backgroundColor = UIColor.colorNamed("Grey-1900")
		let _ = self.view.addGradientBackgroundFull()
		
		
		balancesMoreButton.menu = menuForBalancesMore()
		balancesMoreButton.showsMenuAsPrimaryAction = true
		
		
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
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.refreshControl.endRefreshing()
					self?.hideLoadingView(completion: nil)
			}
		}
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
		
		if indexPath.row == 0 {
			return
		}
		
		if viewModel.isPresentedForSelectingToken, let parent = self.parent as? SendChooseTokenViewController {
			TransactionService.shared.sendData.chosenToken = viewModel.token(atIndexPath: indexPath)
			TransactionService.shared.sendData.chosenNFT = nil
			parent.tokenChosen()
			
		} else {
			TransactionService.shared.sendData.chosenToken = viewModel.token(atIndexPath: indexPath)
			TransactionService.shared.sendData.chosenNFT = nil
			self.performSegue(withIdentifier: "details", sender: self)
		}
	}
	
	func menuForBalancesMore() -> UIMenu {
		let options: [UIAction] = [
			UIAction(title: "Favourites", image: UIImage(named: "context-menu-favourite"), identifier: nil, handler: { [weak self] action in
				self?.alert(withTitle: "Favourites", andMessage: "hold your horses, not done yet")
			}),
			UIAction(title: "View Hidden Tokens", image: UIImage(named: "context-menu-hidden"), identifier: nil, handler: { [weak self] action in
				self?.alert(withTitle: "View Hidden Tokens", andMessage: "hold your horses, not done yet")
			}),
		]
		
		return UIMenu(title: "", image: nil, identifier: nil, options: [], children: options)
	}
}
