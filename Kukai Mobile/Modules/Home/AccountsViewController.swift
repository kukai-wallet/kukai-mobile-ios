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
	private var refreshControl = UIRefreshControl()
	
	public weak var bottomSheetContainer: UIViewController? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if !self.isModal {
			let _ = self.view.addGradientBackgroundFull()
		} else {
			view.backgroundColor = .clear
		}
		
		viewModel.makeDataSource(withTableView: tableView)
		viewModel.delegate = self
		
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.allowsSelectionDuringEditing = true
		
		refreshControl.addAction(UIAction(handler: { [weak self] action in
			self?.viewModel.pullToRefresh(animate: true)
		}), for: .valueChanged)
		tableView.refreshControl = refreshControl
		
		self.navigationItem.setRightBarButtonItems([addButtonContainer, editButtonContainer], animated: false)
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingView(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.refreshControl.endRefreshing()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					self?.refreshControl.endRefreshing()
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.isPresentingForConnectedApps = (bottomSheetContainer != nil)
		deselectCurrentSelection()
		viewModel.refresh(animate: false)
	}
	
	@IBAction func editButtonTapped(_ sender: Any) {
		self.tableView.isEditing = true
		self.navigationItem.title = "Edit Accounts"
		self.navigationItem.hidesBackButton = true
		self.navigationItem.setRightBarButtonItems([doneButtonContainer], animated: false)
	}
	
	@IBAction func doneButtonTapped(_ sender: Any) {
		self.tableView.isEditing = false
		self.navigationItem.title = "Wallets"
		self.navigationItem.hidesBackButton = false
		self.navigationItem.setRightBarButtonItems([addButtonContainer, editButtonContainer], animated: false)
		
		if let cell = tableView.cellForRow(at: viewModel.selectedIndex) {
			cell.setSelected(true, animated: false)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination.presentationController as? UISheetPresentationController {
			dest.delegate = self
		}
		
		if let vc = segue.destination as? EditWalletViewController, let indexPath = sender as? IndexPath {
			vc.selectedWalletMetadata = viewModel.metadataFor(indexPath: indexPath)
			vc.selectedWalletParentIndex = viewModel.parentIndexForIndexPathIfRelevant(indexPath: indexPath)
			
		} else if let vc = segue.destination as? RenameWalletGroupdViewController, let metadata = sender as? WalletMetadata {
			vc.selectedWalletMetadata = metadata
			
		} else if let vc = segue.destination as? RemoveWalletViewController, let metadata = sender as? WalletMetadata {
			vc.selectedWalletMetadata = metadata
		}
	}
}

extension AccountsViewController: AccountsViewModelDelegate {
	
	func allWalletsRemoved() {
		self.navigationController?.popToRootViewController(animated: true)
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
		
		if !tableView.isEditing {
			deselectCurrentSelection()
			
			viewModel.selectedIndex = indexPath
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
			
			guard let metadata = viewModel.metadataFor(indexPath: indexPath) else {
				return
			}
			
			DependencyManager.shared.selectedWalletMetadata = metadata
			
			if let container = bottomSheetContainer {
				container.presentingViewController?.viewWillAppear(true)
				container.dismissBottomSheet()
				
			} else {
				self.navigationController?.popViewController(animated: true)
			}
			
		} else {
			self.performSegue(withIdentifier: "edit", sender: indexPath)
		}
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

extension AccountsViewController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		self.viewModel.refresh(animate: true)
	}
}
