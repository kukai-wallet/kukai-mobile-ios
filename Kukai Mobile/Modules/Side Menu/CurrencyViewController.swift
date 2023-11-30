//
//  CurrencyViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/02/2022.
//

import UIKit
import Combine

class CurrencyViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = CurrencyViewModel()
	private var cancellable: AnyCancellable?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		
		cancellable = viewModel.$state.dropFirst().sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal(completion: nil)
					
				case .failure(_, let errorString):
					self?.hideLoadingModal(completion: {
						self?.windowError(withTitle: "error".localized(), description: errorString)
					})
				
				case .success(let message):
					self?.hideLoadingModal(completion: {
						if message == CurrencyViewModel.didChangeCurrencyMessage {
							self?.navigationController?.popViewController(animated: true)
						}
					})
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		deselectCurrentSelection()
		
		viewModel.selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		self.viewModel.changeCurrency(toIndexPath: indexPath)
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
	
	private func deselectCurrentSelection() {
		tableView.deselectRow(at: viewModel.selectedIndex, animated: true)
		let previousCell = tableView.cellForRow(at: viewModel.selectedIndex)
		previousCell?.setSelected(false, animated: true)
	}
	
	
}
