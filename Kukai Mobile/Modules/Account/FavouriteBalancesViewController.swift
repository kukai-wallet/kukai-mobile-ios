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
					let _ = ""
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
			self.view.layoutIfNeeded()
			
		} else {
			reOrderButton.setTitle("Re-Order", for: .normal)
			subHeadingLabel.isHidden = false
			subHeadingBottomConstraint.isActive = true
			self.view.layoutIfNeeded()
		}
	}
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? FavouriteTokenCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
			
		} else if let c = cell as? TokenBalanceCell {
			c.addGradientBackground(withFrame: c.containerView.bounds)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		viewModel.handleTap(onTableView: tableView, atIndexPath: indexPath)
		
		/*
		TransactionService.shared.sendData.chosenToken = viewModel.token(atIndexPath: indexPath)
		TransactionService.shared.sendData.chosenNFT = nil
		(self.parent as? HiddenTokensMainViewController)?.openTokenDetails()
		*/
	}
}
