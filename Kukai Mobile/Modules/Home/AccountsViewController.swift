//
//  AccountsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class AccountsViewController: UIViewController {
	
	@IBOutlet var addButtonContainer: UIBarButtonItem!
	@IBOutlet var editButtonContainer: UIBarButtonItem!
	@IBOutlet var doneButtonContainer: UIBarButtonItem!
	
	@IBOutlet var tableView: UITableView!
	
	private let viewModel = AccountsViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		self.navigationItem.setRightBarButtonItems([addButtonContainer, editButtonContainer], animated: false)
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					let _ = ""
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		deselectCurrentSelection()
		viewModel.refresh(animate: false)
	}
	
	@IBAction func editButtonTapped(_ sender: Any) {
		self.tableView.isEditing = true
		self.navigationItem.setRightBarButtonItems([doneButtonContainer], animated: false)
	}
	
	@IBAction func doneButtonTapped(_ sender: Any) {
		self.tableView.isEditing = false
		self.navigationItem.setRightBarButtonItems([addButtonContainer, editButtonContainer], animated: false)
	}
}

extension AccountsViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
		
		if indexPath == viewModel.selectedIndex {
			cell.setSelected(true, animated: true)
			
		} else {
			cell.setSelected(false, animated: true)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == 0 { return }
		
		deselectCurrentSelection()
		
		viewModel.selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		guard let metadata = viewModel.metadataFor(indexPath: indexPath) else {
			return
		}
		
		DependencyManager.shared.selectedWalletMetadata = metadata
		self.navigationController?.popViewController(animated: true)
	}
	
	private func deselectCurrentSelection() {
		tableView.deselectRow(at: viewModel.selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: viewModel.selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
}
