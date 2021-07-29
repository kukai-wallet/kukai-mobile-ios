//
//  SideMenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit
import Combine

class SideMenuViewController: UIViewController {

	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuViewModel()
	private var cancellable: AnyCancellable?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// Setup data
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			if case .failure(_, let errorString) = state {
				self?.alert(withTitle: "Error", andMessage: errorString)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Begin off screen to left, on a clear background
		contentViewLeftConstraint.constant = contentViewWidthConstraint.constant * -1
		self.view.backgroundColor = .clear
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		viewModel.refresh(animate: true)
		
		// Fade in background and slide in content view
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.backgroundColor = UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 0.5)
		}
		
		contentViewLeftConstraint.constant = 0
		UIView.animate(withDuration: 1) { [weak self] in
			self?.closeButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
			self?.view.layoutIfNeeded()
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		
		let anticlockAnimation = CABasicAnimation(keyPath: "transform.rotation")
		anticlockAnimation.fromValue = CGFloat.pi
		anticlockAnimation.toValue = 0
		anticlockAnimation.isAdditive = true
		anticlockAnimation.duration = 1.0
		
		contentViewLeftConstraint.constant = contentViewWidthConstraint.constant * -1
		
		UIView.animate(withDuration: 1) { [weak self] in
			self?.closeButton.layer.add(anticlockAnimation, forKey: "rotate")
			self?.closeButton.transform = CGAffineTransform(rotationAngle: -CGFloat.pi)
			self?.view.backgroundColor = .clear
			self?.view.layoutIfNeeded()
			
		} completion: { [weak self] finish in
			self?.dismiss(animated: false, completion: nil)
		}
	}
}

extension SideMenuViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row != DependencyManager.shared.selectedWalletIndex {
			tableView.cellForRow(at: IndexPath(row: DependencyManager.shared.selectedWalletIndex, section: 0))?.accessoryType = .none
			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
			
			DependencyManager.shared.selectedWalletIndex = indexPath.row
			closeButtonTapped(self)
		}
	}
}
