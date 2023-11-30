//
//  SideMenuSettingsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/09/2023.
//

import UIKit
import Combine

class SideMenuSettingsViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuSettingsViewModel()
	
	private var bag = [AnyCancellable]()
	private var gradient = CAGradientLayer()
	private let sectionFooterSpacer = UIView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
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
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.gradient.removeFromSuperlayer()
				self?.gradient = self?.view.addGradientBackgroundFull() ?? CAGradientLayer()
				
				self?.tableView.reloadData()
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination.presentationController as? UISheetPresentationController {
			dest.delegate = self
		}
	}
}

extension SideMenuSettingsViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return sectionFooterSpacer
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 4
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		cell.addGradientBackground(withFrame: cell.contentView.bounds, toView: cell.contentView)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let segue = viewModel.segue(forIndexPath: indexPath) {
			self.performSegue(withIdentifier: segue, sender: self)
		}
	}
}

// MARK: - UISheetPresentationControllerDelegate

extension SideMenuSettingsViewController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		viewModel.refresh(animate: true)
	}
}
