//
//  AddWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2022.
//

import UIKit
import Combine

class AddWalletViewController: UIViewController, UITableViewDelegate {
	
	@IBOutlet weak var tableView: UITableView!
	
	private let viewModel = AddWalletViewModel()
	private var bag = [AnyCancellable]()
	private var selectedIndex = IndexPath(row: -1, section: -1)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		tableView.sectionFooterHeight = 8
		
		
		viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					break
					
				case .failure(_, let errorString):
					self?.windowError(withTitle: "error".localized(), description: errorString)
					
				case .success:
					break
			}
		}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		viewModel.refresh(animate: false)
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard let _ = viewModel.sectionTitles[section] else {
			return 0.1
		}
		
		return 40
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let title = viewModel.sectionTitles[section] else {
			return nil
		}
		
		let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 22))
		view.backgroundColor = .clear
		
		let titleLabel = UILabel(frame: view.bounds)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.text = title
		titleLabel.font = .custom(ofType: .bold, andSize: 16)
		titleLabel.textColor = .colorNamed("Txt10")
		titleLabel.textAlignment = .center
		view.addSubview(titleLabel)
		
		NSLayoutConstraint.activate([
			titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
		])
		
		return view
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView(frame: CGRect.zero)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if selectedIndex == indexPath {
			tableView.deselectRow(at: indexPath, animated: true)
			selectedIndex = IndexPath(row: -1, section: -1)
		} else {
			selectedIndex = indexPath
		}
		
		if let optionalOption = viewModel.handleTap(atIndexPath: indexPath) {
			if optionalOption == "hd" {
				CreateWalletViewController.createAndCacheHDWallet { errorMessage in
					if let error = errorMessage {
						self.windowError(withTitle: "error".localized(), description: error)
					} else {
						self.navigationController?.popViewController(animated: true)
					}
				}
			} else {
				self.performSegue(withIdentifier: optionalOption, sender: nil)
			}
		}
	}
}
