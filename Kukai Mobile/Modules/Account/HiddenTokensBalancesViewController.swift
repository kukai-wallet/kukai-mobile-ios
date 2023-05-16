//
//  HiddenTokensBalancesViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit
import Combine

class HiddenTokensBalancesViewController: UIViewController, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = HiddenBalancesViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
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
	
	
	
	// MARK: Tableview
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? UITableViewCellContainerView {
			c.addGradientBackground(withFrame: c.containerView.bounds, toView: c.containerView)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		TransactionService.shared.resetState()
		TransactionService.shared.sendData.chosenToken = viewModel.token(atIndexPath: indexPath)
		TransactionService.shared.sendData.chosenNFT = nil
		(self.parent as? HiddenTokensMainViewController)?.openTokenDetails()
	}
}
