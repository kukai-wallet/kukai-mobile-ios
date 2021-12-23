//
//  AssetsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit
import Combine

class AssetsViewController: UIViewController {

	@IBOutlet weak var accountNavButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = AssetsViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		
		// Prevent nav button from consuming the entire nav bar
		accountNavButton.addConstraint(NSLayoutConstraint(item: accountNavButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 140))
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.accountNavButton.setTitle(self?.viewModel.heading, for: .normal)
					self?.hideLoadingView(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		tableView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0);
		viewModel.refresh(animate: true)
	}
}
