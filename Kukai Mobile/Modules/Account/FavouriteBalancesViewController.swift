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
	@IBOutlet weak var subHeadingLabel: UILabel!
	
	@IBOutlet var subHeadingBottomConstraint: NSLayoutConstraint!
	@IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
	
	private var isReOrder = false
	private let viewModel = FavouriteBalancesViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					let _ = ""
					
				case .failure(_, let errorString):
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					print("calling success")
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
			reOrderButton.setTitle("Done", for: .normal)
			subHeadingLabel.isHidden = true
			subHeadingBottomConstraint.isActive = false
			tableViewTopConstraint.isActive = true
			
			UIView.animate(withDuration: 0.3, delay: 0) {
				self.view.layoutIfNeeded()
			}
			
			viewModel.isEditing = true
			viewModel.reload(animating: true)
			viewModel.refresh(animate: true)
			tableView.isEditing = true // set tableView editing after so it doesn't edit existing cells
			
		} else {
			reOrderButton.setTitle("Re-Order", for: .normal)
			subHeadingLabel.isHidden = false
			subHeadingBottomConstraint.isActive = true
			tableViewTopConstraint.isActive = false
			
			UIView.animate(withDuration: 0.3, delay: 0) {
				self.view.layoutIfNeeded()
			}
			
			tableView.isEditing = false // set tableview editing before so it does edit exising cells
			viewModel.isEditing = false
			viewModel.reload(animating: false)
			viewModel.refresh(animate: true)
		}
	}
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		// TODO: make a protocol for generic support
		if let c = cell as? FavouriteTokenCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
			
		} else if let c = cell as? TokenBalanceCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
			
		} else if let c = cell as? FavouriteTokenEditCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
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
