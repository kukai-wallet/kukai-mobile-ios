//
//  NetworkChooserViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift
import Combine

class NetworkChooserViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = NetworkChooserViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
		
		cancellable = viewModel.$state.dropFirst().sink { [weak self] state in
			switch state {
				case .loading:
					//self?.showLoadingModal(completion: nil)
					let _ = ""
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
				
				case .success(_):
					let _ = ""
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: true)
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard indexPath.row != 0, let networkType = viewModel.networkTypeFromIndex(indexPath: indexPath) else { return }
		deselectCurrentSelection()
		
		viewModel.selectedIndex = indexPath
		tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		
		if networkType == .experimental {
			self.performSegue(withIdentifier: "experimental", sender: nil)
			
		} else {
			/*
			self.showLoadingModal {
				let previousNetwork = DependencyManager.shared.currentNetworkType
				
				DependencyManager.shared.setNetworkTo(networkTo: networkType)
				DependencyManager.shared.tezosNodeClient.getNetworkInformation { success, error in
					if let err = error {
						DependencyManager.shared.setNetworkTo(networkTo: previousNetwork)
						self.windowError(withTitle: "error".localized(), description: err.localizedDescription)
					}
				}
				
			}*/
			
			DependencyManager.shared.setNetworkTo(networkTo: networkType)
			self.navigationController?.popToHome()
		}
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
