//
//  SideMenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/03/2023.
//

import UIKit
import Combine
import KukaiCoreSwift

class SideMenuViewController: UIViewController {

	@IBOutlet weak var closeButton: CustomisableButton!
	@IBOutlet weak var scanButton: CustomisableButton!
	
	@IBOutlet weak var currentAccountContainer: UIView!
	@IBOutlet weak var currentAccountAliasStackView: UIStackView!
	@IBOutlet weak var aliasIcon: UIImageView!
	@IBOutlet weak var aliasTitle: UILabel!
	@IBOutlet weak var aliasSubtitle: UILabel!
	
	@IBOutlet weak var currentAccountRegularStackView: UIStackView!
	@IBOutlet weak var regularIcon: UIImageView!
	@IBOutlet weak var regularTitle: UILabel!
	
	@IBOutlet weak var getTezButton: CustomisableButton!
	@IBOutlet weak var copyButton: CustomisableButton!
	@IBOutlet weak var showQRButton: CustomisableButton!
	
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuViewModel()
	private var bag = [AnyCancellable]()
	private var previousPanX: CGFloat = 0
	
	public weak var homeTabBarController: HomeTabBarController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		closeButton.accessibilityIdentifier = "side-menu-close-button"
		
		self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(touched(_:))))
		
		scanButton.configuration?.imagePlacement = .trailing
		scanButton.configuration?.imagePadding = 6
		
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
					self.alert(withTitle: "Error", andMessage: message)
			}
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
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
		
		guard let wallet = DependencyManager.shared.selectedWalletMetadata else { return }
		let media = TransactionService.walletMedia(forWalletMetadata: wallet, ofSize: .size_22)
		
		if let subtitle = media.subtitle {
			currentAccountRegularStackView.isHidden = true
			currentAccountAliasStackView.isHidden = false
			
			aliasIcon.image = media.image
			aliasTitle.text = media.title
			aliasSubtitle.text = subtitle
			
		} else {
			currentAccountAliasStackView.isHidden = true
			currentAccountRegularStackView.isHidden = false
			
			regularIcon.image = media.image
			regularTitle.text = media.title
		}
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		let frame = self.view.frame
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.homeTabBarController?.sideMenuTintView.alpha = 0
			self?.view.frame = CGRect(x: frame.origin.x + (frame.width * -1), y: 0, width: frame.width, height: frame.height)
			
		} completion: { [weak self] done in
			self?.homeTabBarController?.sideMenuTintView.removeFromSuperview()
			self?.view.removeFromSuperview()
			
			DependencyManager.shared.sideMenuOpen = false
		}
	}
	
	@objc private func touched(_ gestureRecognizer: UIPanGestureRecognizer) {
		let velocity = gestureRecognizer.velocity(in: view)
		let location = gestureRecognizer.location(in: view)
		let currentFrame = self.view.frame
		
		let currentPanX = location.x
		if previousPanX == 0 {
			previousPanX = currentPanX
		}
		
		let change = (previousPanX - currentPanX)
		let newX = currentFrame.origin.x - change
		
		
		// If user is panning left, animate the position of the view left
		// If view reaches a treshold, close
		// If attempt to pan right (> 0), cancel
		if newX > 0 {
			return
			
		} else if (newX * -1) >= (currentFrame.width / 1.5) {
			gestureRecognizer.isEnabled = false
			self.closeTapped(self)
			return
			
		} else {
			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
				self?.view.frame = CGRect(x: currentFrame.origin.x - change, y: 0, width: currentFrame.width, height: currentFrame.height)
			}, completion: nil)
		}
		
		
		// If gesture ends without reaching close treshold, examine veloicity
		// If velocity was greater than a treshold, close anyway
		// else reset position
		if gestureRecognizer.state == .ended {
			if velocity.x < -200 {
				self.closeTapped(self)
				
			} else {
				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
					self?.view.frame = CGRect(x: 0, y: 0, width: currentFrame.width, height: currentFrame.height)
				}, completion: nil)
			}
		}
	}
	
	@IBAction func scanTapped(_ sender: Any) {
		self.closeTapped(sender)
		self.homeTabBarController?.openScanner()
	}
	
	@IBAction func getTezTapped(_ sender: Any) {
		self.alert(errorWithMessage: "Under construction")
	}
	
	@IBAction func copyTapped(_ sender: UIButton) {
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		
		Toast.shared.show(withMessage: "\(address.truncateTezosAddress()) copied!", attachedTo: sender)
		UIPasteboard.general.string = address
	}
	
	@IBAction func showQRTapped(_ sender: Any) {
		homeTabBarController?.performSegue(withIdentifier: "side-menu-show-qr", sender: nil)
	}
	
	@IBAction func swapTapped(_ sender: Any) {
		
	}
}

extension SideMenuViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard let details = viewModel.details(forIndexPath: indexPath) else { return }
		
		if let url = details.url, UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
			
		} else if let segue = details.segue {
			if details.collapseAndNavigate == true {
				
				self.closeTapped(self)
				homeTabBarController?.performSegue(withIdentifier: segue, sender: nil)
				
			} else {
				homeTabBarController?.performSegue(withIdentifier: segue, sender: nil)
			}
			
		} else {
			shareURL()
		}
	}
	
	func shareURL() {
		if let shareURL = NSURL(string: "https://kukai.app") {
			let objectsToShare = [shareURL]
			let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
			self.present(activityVC, animated: true, completion: nil)
		}
	}
}
