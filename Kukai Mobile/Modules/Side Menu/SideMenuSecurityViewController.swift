//
//  SideMenuSecurityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/09/2023.
//

import UIKit
import Combine

class SideMenuSecurityViewController: UIViewController {
	
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuSecurityViewModel()
	
	private var bag = [AnyCancellable]()
	private let sectionFooterSpacer = UIView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		// Setup data
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionHeaderTopPadding = 0
		tableView.sectionHeaderHeight = 0
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		sectionFooterSpacer.backgroundColor = .clear
		
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
		
		DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
	}
}

extension SideMenuSecurityViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return sectionFooterSpacer
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let res = viewModel.segue(forIndexPath: indexPath)
		
		if let segue = res.segue {
			self.performSegue(withIdentifier: segue, sender: self)
			
		} else if let url = res.url {
			UIApplication.shared.open(url)
		}
	}
}
