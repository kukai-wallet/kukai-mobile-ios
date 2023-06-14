//
//  StakeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class StakeViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = StakeViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		viewModel.infoDelegate = self
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingView(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success(let successMessage):
					self?.hideLoadingView(completion: nil)
					
					if let message = successMessage {
						self?.alert(withTitle: "Success", andMessage: message)
						self?.navigationController?.popViewController(animated: true)
					}
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
}

extension StakeViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return viewModel.heightForHeaderInSection(section, forTableView: tableView)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return viewModel.viewForHeaderInSection(section, forTableView: tableView)
	}
}

extension StakeViewController: PublicBakerCellInfoDelegate {
	
	func infoButtonTapped(forBaker: TzKTBaker?) {
		self.performSegue(withIdentifier: "info", sender: forBaker)
	}
}
