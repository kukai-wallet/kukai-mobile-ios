//
//  SendChooseTokenViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import Combine

class SendChooseTokenViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = SendChooseTokenViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showActivity(clearBackground: false)
					
				case .failure(_, let errorString):
					self?.hideActivity()
					self?.alert(withTitle: "Error", andMessage: errorString)
					
				case .success:
					self?.hideActivity()
			}
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		viewModel.refresh(animate: true)
	}
}

extension SendChooseTokenViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let chosenToken = viewModel.token(forIndexPath: indexPath) {
			TransactionService.shared.sendData.chosenToken = chosenToken
			self.performSegue(withIdentifier: "chooseAmount", sender: self)
			
		} else {
			self.alert(errorWithMessage: "Can't find token info")
		}
	}
}
