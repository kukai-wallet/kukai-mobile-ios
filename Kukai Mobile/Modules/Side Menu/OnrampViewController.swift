//
//  OnrampViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/08/2023.
//

import UIKit
import Combine
import SafariServices

class OnrampViewController: UIViewController, UITableViewDelegate {

	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = OnrampViewModel()
	
	private var bag = [AnyCancellable]()
	private var safariViewController: SFSafariViewController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		// Setup data
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		viewModel.$state.sink { [weak self] state in
			guard let self = self else { return }
			
			switch state {
				case .loading:
					let _ = ""
					
				case .success(_):
					let _ = ""
					
				case .failure(_, let message):
					self.windowError(withTitle: "error".localized(), description: message)
			}
		}.store(in: &bag)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.showLoadingView()
		
		viewModel.url(forIndexPath: indexPath) { [weak self] result in
			self?.hideLoadingView()
			guard let res = try? result.get() else {
				self?.windowError(withTitle: "error".localized(), description: "error-onramp-generic".localized())
				return
			}
			
			self?.safariViewController = SFSafariViewController(url: res)
			
			if let vc = self?.safariViewController {
				vc.modalPresentationStyle = .pageSheet
				self?.present(vc, animated: true)
			}
		}
	}
}
