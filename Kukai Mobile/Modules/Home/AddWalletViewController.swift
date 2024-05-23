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
	private var gradient = CAGradientLayer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
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
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.layoutIfNeeded()
		
		if let c = cell as? AccountsAddOptionCell {
			c.addGradientBackground(withFrame: c.contentView.bounds, toView: c.contentView, roundCorners: false)
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let optionalOption = viewModel.handleTap(atIndexPath: indexPath) {
			print("do: \(optionalOption)")
		}
	}
	
	
	
	
	/*
	var bottomSheetMaxHeight: CGFloat = 330
	var dimBackground: Bool = true
	
	@IBOutlet var createWalletButton: CustomisableButton!
	@IBOutlet var existingWalletButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		createWalletButton.customButtonType = .primary
		existingWalletButton.customButtonType = .secondary
    }
	
	@IBAction func createTapped(_ sender: Any) {
		let parent = (self.presentingViewController as? UINavigationController)?.viewControllers.last
		
		self.dismiss(animated: true) {
			parent?.performSegue(withIdentifier: "create", sender: nil)
		}
	}
	
	@IBAction func existingTapped(_ sender: Any) {
		let parent = (self.presentingViewController as? UINavigationController)?.viewControllers.last
		
		self.dismiss(animated: true) {
			parent?.performSegue(withIdentifier: "existing", sender: nil)
		}
	}
	*/
}
