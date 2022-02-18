//
//  CollectiblesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit
import Combine

class CollectiblesViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = CollectiblesViewModel()
	private var cancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		viewModel.tapCell(forTableView: tableView, atIndexPath: indexPath)
	}
}
