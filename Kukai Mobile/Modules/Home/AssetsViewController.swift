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
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.accountNavButton.setTitle(self?.viewModel.heading, for: .normal)
					self?.hideLoadingModal(completion: nil)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		tableView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0);
		viewModel.refresh(animate: true)
	}
}
