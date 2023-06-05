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

	@IBOutlet weak var scanButton: CustomisableButton!
	
	@IBOutlet weak var currentAccountContainer: UIView!
	@IBOutlet weak var currentAccountAliasStackView: UIStackView!
	@IBOutlet weak var aliasIcon: UIImageView!
	@IBOutlet weak var aliasTitle: UILabel!
	@IBOutlet weak var aliasSubtitle: UILabel!
	
	@IBOutlet weak var currentAccountRegularStackView: UIStackView!
	@IBOutlet weak var regularIcon: UIImageView!
	@IBOutlet weak var regularTitle: UILabel!
	
	@IBOutlet var buttonLabels: [UILabel]!
	
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuViewModel()
	private var bag = [AnyCancellable]()
	
	public weak var homeTabBarController: HomeTabBarController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
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
				
				self?.view.backgroundColor = .colorNamed("BGSideMenu")
				self?.scanButton.tintColor = .colorNamed("Txt0")
				
				self?.aliasTitle.textColor = .colorNamed("Txt2")
				self?.aliasSubtitle.textColor = .colorNamed("Txt10")
				self?.regularTitle.textColor = .colorNamed("Txt2")
				
				self?.buttonLabels.forEach({ $0.textColor = .colorNamed("TxtBtnSec1") })
				
				self?.currentAccountContainer.backgroundColor = .colorNamed("BG2")
				
				self?.tableView.visibleCells.forEach({ ($0 as? UITableViewCellThemeUpdated)?.themeUpdated() })
				
				
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
			self?.view.frame = CGRect(x: frame.width * -1, y: 0, width: frame.width, height: frame.height)
			
		} completion: { [weak self] done in
			self?.view.removeFromSuperview()
		}
	}
	
	@IBAction func scanTapped(_ sender: Any) {
		self.closeTapped(sender)
		self.homeTabBarController?.openScanner()
	}
	
	@IBAction func getTezTapped(_ sender: Any) {
	}
	
	@IBAction func copyTapped(_ sender: Any) {
		UIPasteboard.general.string = DependencyManager.shared.selectedWalletAddress
	}
	
	@IBAction func showQRTapped(_ sender: Any) {
	}
	
	@IBAction func swapTapped(_ sender: Any) {
		
	}
	
	/*
	@IBAction func deleteAllTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Are you Sure?", message: "Are you sure you want to delete all your wallets? This in unrecoverable", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
			DependencyManager.shared.tzktClient.stopListeningForAccountChanges()
			
			let _ = WalletCacheService().deleteAllCacheAndKeys()
			TransactionService.shared.resetState()
			DependencyManager.shared.walletList = WalletMetadataList(socialWallets: [], hdWallets: [], linearWallets: [], ledgerWallets: [])
			
			let domain = Bundle.main.bundleIdentifier ?? "app.kukai.mobile"
			UserDefaults.standard.removePersistentDomain(forName: domain)
			
			DependencyManager.shared.setDefaultMainnetURLs(supressUpdateNotification: true)
			
			self.closeTapped(sender)
			self.homeTabBarController?.navigationController?.popToRootViewController(animated: true)
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		self.present(alert, animated: true)
	}
	*/
}

extension SideMenuViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard let segueDetails = viewModel.segue(forIndexPath: indexPath) else {
			return
		}
		
		if segueDetails.collapseAndNavigate {
			self.closeTapped(self)
			homeTabBarController?.performSegue(withIdentifier: segueDetails.segue, sender: nil)
			
		} else {
			homeTabBarController?.performSegue(withIdentifier: segueDetails.segue, sender: nil)
		}
	}
}
