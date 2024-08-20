//
//  AccountsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2022.
//

import UIKit
import Combine
import KukaiCoreSwift

class AccountsViewController: UIViewController, BottomSheetContainerDelegate {
	
	@IBOutlet var addButtonContainer: UIBarButtonItem!
	@IBOutlet var editButtonContainer: UIBarButtonItem!
	@IBOutlet var doneButtonContainer: UIBarButtonItem!
	
	@IBOutlet var tableView: UITableView!
	
	private let viewModel = AccountsViewModel()
	private var cancellable: AnyCancellable?
	private var refreshControl = UIRefreshControl()
	private var editingIndexPath: IndexPath? = nil
	
	public weak var bottomSheetContainer: UIViewController? = nil
	public var addressToMarkAsSelected: String? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.removeOnboardingScreens()
		
		addButtonContainer.accessibilityIdentifier = "accounts-nav-add"
		editButtonContainer.accessibilityIdentifier = "accounts-nav-edit"
		doneButtonContainer.accessibilityIdentifier = "accounts-nav-done"
		
		if !self.isModal {
			GradientView.add(toView: self.view, withType: .fullScreenBackground)
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
					//self?.showLoadingView()
					let _ = ""
					
				case .failure(_, let errorString):
					//self?.hideLoadingView(completion: nil)
					self?.refreshControl.endRefreshing()
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					//self?.hideLoadingView(completion: nil)
					self?.refreshControl.endRefreshing()
					
					guard self?.tableView.isEditing == false else {
						self?.editingIndexPath = nil
						return
					}
					
					if self?.viewModel.scrollToSelected() == true {
						let selectedIndex = self?.viewModel.selectedIndex ?? IndexPath(row: 0, section: 0)
						let deadlineAdjustment: TimeInterval = (self?.bottomSheetContainer != nil) ? 0.1 : 0 // need an artifical delay within bottom sheets for some reason, else it doesn't work
						
						// When displayed inside a bottom sheet, it can't get the correct frame until after its started rendering, resulting in it doing nothing
						// need to add a slight delay so it picks up the correct sizing and then animates
						DispatchQueue.main.asyncAfter(deadline: .now() + deadlineAdjustment) { [weak self] in
							if selectedIndex.row >= (self?.tableView.numberOfRows(inSection: selectedIndex.section) ?? 0) {
								self?.tableView.scrollToRow(at: IndexPath(row: 0, section: selectedIndex.section), at: .middle, animated: true)
							} else {
								self?.tableView.scrollToRow(at: selectedIndex, at: .middle, animated: true)
							}
						}
						
					} else if let newSubAccountIndex = self?.viewModel.newAddressIndexPath {
						if newSubAccountIndex.row >= (self?.tableView.numberOfRows(inSection: newSubAccountIndex.section) ?? 0) {
							self?.tableView.scrollToRow(at: IndexPath(row: 0, section: newSubAccountIndex.section), at: .middle, animated: true)
						} else {
							self?.tableView.scrollToRow(at: newSubAccountIndex, at: .middle, animated: true)
						}
					}
			}
		}
	}
	
	func bottomSheetDataChanged() {
		viewModel.isPresentingForConnectedApps = (bottomSheetContainer != nil)
		viewModel.addressToMarkAsSelected = addressToMarkAsSelected
		deselectCurrentSelection()
		viewModel.refresh(animate: false)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		bottomSheetDataChanged()
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
			self.editingIndexPath = indexPath
			vc.selectedWalletMetadata = viewModel.metadataFor(indexPath: indexPath)
			vc.selectedWalletParentIndex = viewModel.parentIndexForIndexPathIfRelevant(indexPath: indexPath)
			vc.isLastSubAccount = viewModel.isLastSubAccount(indexPath: indexPath)
			
		} else if let vc = segue.destination as? RenameWalletGroupdViewController, let metadata = sender as? WalletMetadata {
			vc.selectedWalletMetadata = metadata
			
		} else if let vc = segue.destination as? AddCustomPathViewController, let metadata = sender as? WalletMetadata {
			vc.selectedWalletMetadata = metadata
			
		} else if let vc = segue.destination as? RemoveWalletViewController {
			
			if let indexPath = self.editingIndexPath {
				vc.selectedWalletMetadata = viewModel.metadataFor(indexPath: indexPath)
				vc.selectedWalletParentIndex = viewModel.parentIndexForIndexPathIfRelevant(indexPath: indexPath)
				
			} else if let metadata = sender as? WalletMetadata {
				vc.selectedWalletMetadata = metadata
			}
		}
	}
}

extension AccountsViewController: AccountsViewModelDelegate {
	
	func allWalletsRemoved() {
		self.navigationController?.popToRootViewController(animated: true)
		DependencyManager.shared.selectedWalletMetadata = nil
	}
}

extension AccountsViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath == viewModel.selectedIndex {
			cell.setSelected(true, animated: true)
			
		} else {
			cell.setSelected(false, animated: true)
		}
		
		if let c = cell as? AccountItemCell, c.newIndicatorView?.isHidden == false {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				c.newIndicatorView?.shake()
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == 0 { return }
		
		if viewModel.handleMoreCellIfNeeded(indexPath: indexPath) {
			tableView.scrollToRow(at: IndexPath(row: 0, section: indexPath.section), at: .top, animated: true)
			return
		}
		
		guard let metadata = viewModel.metadataFor(indexPath: indexPath) else {
			return
		}
		
		if !tableView.isEditing {
			deselectCurrentSelection()
			
			viewModel.selectedIndex = indexPath
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
			
			if let container = bottomSheetContainer, bottomSheetContainer?.presentingViewController is WalletConnectPairViewController {
				DependencyManager.shared.temporarySelectedWalletMetadata = metadata
				(container.presentingViewController as? BottomSheetContainerDelegate)?.bottomSheetDataChanged()
				container.dismissBottomSheet()
				
			} else if let container = bottomSheetContainer, let parentNav = (container.presentingViewController as? UINavigationController), let vc = (parentNav.viewControllers[parentNav.viewControllers.count-1] as? BottomSheetContainerDelegate) {
				DependencyManager.shared.temporarySelectedWalletMetadata = metadata
				vc.bottomSheetDataChanged()
				container.dismissBottomSheet()
				
			} else {
				DependencyManager.shared.selectedWalletMetadata = metadata
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
