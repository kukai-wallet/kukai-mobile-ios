//
//  SwapTokenViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/11/2021.
//

import UIKit
import Combine

class SwapTokenViewController: UITableViewController, UISearchResultsUpdating {
	
	private let viewModel = SwapTokenViewModel()
	private var cancellable: AnyCancellable?
	private let searchController = UISearchController(searchResultsController: nil)
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		
		searchController.searchResultsUpdater = self
		searchController.hidesNavigationBarDuringPresentation = false
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "Search"
		searchController.searchBar.showsCancelButton = false
		
		navigationItem.searchController = searchController
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					print("")
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingModal(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: true)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		searchController.isActive = true
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		TransactionService.shared.recordChosen(exchange: self.viewModel.exchange(forIndexPath: indexPath))
		self.navigationController?.popViewController(animated: true)
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let title = self.viewModel.titleForSection(section) else {
			return nil
		}
		
		let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
		view.backgroundColor = .clear
		
		let label = UILabel(frame: CGRect(x: 4, y: 4, width: 100, height: 12))
		label.text = title
		label.font = UIFont.systemFont(ofSize: 14)
		label.textColor = .lightGray
		
		view.addSubview(label)
		return view
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 20
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		self.viewModel.filterFor(searchController.searchBar.text)
		self.tableView.reloadData()
	}
}
