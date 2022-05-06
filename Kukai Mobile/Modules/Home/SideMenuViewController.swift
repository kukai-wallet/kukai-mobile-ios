//
//  SideMenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit
import KukaiCoreSwift
import Combine

class SideMenuViewController: UIViewController {

	@IBOutlet weak var contentView: UIView!
	@IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
	@IBOutlet weak var closeButton: UIButton!
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuViewModel()
	private var cancellable: AnyCancellable?
	
	private var previousRightConstant: CGFloat = 0
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// Setup data
		viewModel.makeDataSource(withTableView: tableView)
		tableView.dataSource = viewModel.dataSource
		tableView.delegate = self
		
		cancellable = viewModel.$state.sink { [weak self] state in
			guard let self = self else { return }
			
			switch state {
				case .loading:
					let _ = ""
					
				case .success(_):
					
					// Always seems to be an extra section, so 1 section left = no content
					if self.viewModel.dataSource?.numberOfSections(in: self.tableView) == 1 {
						self.closeAndBackToStart()
					}
					
				case .failure(_, let message):
					self.alert(withTitle: "Error", andMessage: message)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Begin off screen to left, on a clear background
		previousRightConstant = contentViewRightConstraint.constant
		contentViewLeftConstraint.constant = ((UIApplication.shared.currentWindow?.frame.width ?? 0) - contentViewRightConstraint.constant) * -1
		contentViewRightConstraint.constant = ((UIApplication.shared.currentWindow?.frame.width ?? 0) + contentViewRightConstraint.constant)
		
		self.view.backgroundColor = .clear
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		viewModel.refresh(animate: true)
		
		// Fade in background and slide in content view
		UIView.animate(withDuration: 0.25) { [weak self] in
			self?.view.backgroundColor = UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 0.5)
		}
		
		contentViewLeftConstraint.constant = 0
		contentViewRightConstraint.constant = self.previousRightConstant
		UIView.animate(withDuration: 0.5) { [weak self] in
			self?.closeButton.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
			self?.view.layoutIfNeeded()
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		
		let anticlockAnimation = CABasicAnimation(keyPath: "transform.rotation")
		anticlockAnimation.fromValue = CGFloat.pi
		anticlockAnimation.toValue = 0
		anticlockAnimation.isAdditive = true
		anticlockAnimation.duration = 0.5
		
		contentViewLeftConstraint.constant = ((UIApplication.shared.currentWindow?.frame.width ?? 0) - contentViewRightConstraint.constant) * -1
		contentViewRightConstraint.constant = ((UIApplication.shared.currentWindow?.frame.width ?? 0) + contentViewRightConstraint.constant)
		
		UIView.animate(withDuration: 0.5) { [weak self] in
			self?.closeButton.layer.add(anticlockAnimation, forKey: "rotate")
			self?.closeButton.transform = CGAffineTransform(rotationAngle: -CGFloat.pi)
			self?.view.backgroundColor = .clear
			self?.view.layoutIfNeeded()
			
		} completion: { [weak self] finish in
			self?.dismiss(animated: false, completion: nil)
		}
	}
	
	public func refeshWallets() {
		viewModel.refresh(animate: true)
	}
	
	func closeAndBackToStart() {
		closeButtonTapped(self)
		let _ = WalletCacheService().deleteCacheAndKeys()
		DependencyManager.shared.balanceService.deleteAllCachedData()
		TransactionService.shared.resetState()
		DependencyManager.shared.tzktClient.stopListeningForAccountChanges()
		
		(self.presentingViewController as? UINavigationController)?.popToRootViewController(animated: true)
	}
}

extension SideMenuViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedIndex = DependencyManager.shared.selectedWalletIndex
		
		// If we want to select the parent wallet, its WalletIndex(parent: x, child: nil)
		// Selecting the first child, its WalletIndex(parent: x, child: 0)
		// Because the parent is the first cell in each section, we need to add or subtract 1 from the indexPath.row when dealing with `selectedWalletIndex`
		if indexPath.section != selectedIndex.parent || indexPath.row != (selectedIndex.child ?? -1) + 1 {
			(tableView.cellForRow(at: indexPath) as? AccountBasicCell)?.setBorder(true)
			
			DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: indexPath.section, child: (indexPath.row == 0 ? nil : indexPath.row-1))
			closeButtonTapped(self)
		}
	}
}
