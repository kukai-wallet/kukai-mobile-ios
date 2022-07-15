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
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	
	private var coingeckservice: CoinGeckoService? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.refreshType = .refreshEverything
			self?.viewModel.refresh(animate: true)
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
		viewModel.isPresentedForSelectingToken = (self.parent != nil && self.tabBarController == nil)
		viewModel.refreshIfNeeded()
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return viewModel.heightForHeaderInSection(section, forTableView: tableView)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return viewModel.viewForHeaderInSection(section, forTableView: tableView)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
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
}
