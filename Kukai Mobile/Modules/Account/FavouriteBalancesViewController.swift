//
//  FavouriteBalancesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit
import Combine

class FavouriteBalancesViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var reOrderButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
	
	private let viewModel = FavouriteBalancesViewModel()
	private var cancellable: AnyCancellable?
	private var isReOrder = false
	private let sectionFooterSpacer = UIView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		sectionFooterSpacer.backgroundColor = .clear
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.reOrderButton.isHidden = !(self?.viewModel.showReorderButton() ?? false)
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refresh(animate: false)
	}
	
	@IBAction func reOrderButtonTapped(_ sender: Any) {
		isReOrder = !isReOrder
		
		if isReOrder {
			self.title = "Re-Order Favourites"
			
			reOrderButton.setTitle("Done", for: .normal)
			tableViewTopConstraint.isActive = true
			
			viewModel.isEditing = true
			viewModel.reload(animating: true)
			viewModel.refresh(animate: true)
			tableView.isEditing = true // set tableView editing after so it doesn't edit existing cells
			
		} else {
			self.title = "Favourites"
			
			reOrderButton.setTitle("Re-Order", for: .normal)
			tableViewTopConstraint.isActive = false
			
			tableView.isEditing = false // set tableview editing before so it does edit exising cells
			viewModel.isEditing = false
			viewModel.reload(animating: false)
			viewModel.refresh(animate: true)
		}
	}
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 62
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return sectionFooterSpacer
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		viewModel.handleTap(onTableView: tableView, atIndexPath: indexPath)
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .none
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
}
