//
//  AddAccountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/05/2024.
//

import UIKit
import Combine
import KukaiCoreSwift

class AddAccountViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = AddAccountViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionFooterHeight = 8
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					break
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					break
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: false)
	}
}

extension AddAccountViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		let clearView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
		clearView.backgroundColor = .clear
		return clearView
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row != 0 { return }
		
		guard let metadata = viewModel.metadataFor(indexPath: indexPath) else {
			return
		}
		
		deselectCurrentSelection()
			
		viewModel.selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		self.showLoadingView()
		AddAccountViewModel.addAccount(forMetadata: metadata, hdWalletIndex: indexPath.section, forceMainnet: false) { [weak self] errorTitle, errorMessage in
			self?.hideLoadingView()
			
			if let title = errorTitle, let message = errorMessage {
				self?.windowError(withTitle: title, description: message)
				
			} else if let previous = self?.navigationController?.viewControllers.first(where: { $0 is AccountsViewController }) {
				self?.navigationController?.popToViewController(previous, animated: true)
			}
		}
	}
	
	private func deselectCurrentSelection() {
		tableView.deselectRow(at: viewModel.selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: viewModel.selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
}
