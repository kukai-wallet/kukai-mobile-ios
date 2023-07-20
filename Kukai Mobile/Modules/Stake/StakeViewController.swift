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
	private let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 2))
	private let blankView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionHeaderHeight = 0
		tableView.sectionFooterHeight = 4
		tableView.tableHeaderView = blankView
		footerView.backgroundColor = .clear
		
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
	
	public func enteredCustomBaker(address: String) {
		self.viewModel.setDelegateAndRefresh(toAddress: address) { [weak self] result in
			if case .failure(let error) = result {
				self?.hideLoadingView()
				self?.alert(errorWithMessage: error.description)
			}
		}
	}
}

extension StakeViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return footerView
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.bounds, toView: c)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let baker = viewModel.bakerFor(indexPath: indexPath) {
			viewModel.setDelegateAndRefresh(toAddress: baker.address) { [weak self] result in
				if case .failure(let error) = result {
					self?.hideLoadingView()
					self?.alert(errorWithMessage: error.description)
				}
			}
		} else if viewModel.isEnterCustom(indePath: indexPath) {
			self.performSegue(withIdentifier: "custom", sender: nil)
		}
	}
}
