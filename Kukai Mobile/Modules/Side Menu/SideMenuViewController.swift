//
//  SideMenuViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/03/2023.
//

import UIKit
import Combine

class SideMenuViewController: UIViewController {

	@IBOutlet weak var scanButton: CustomisableButton!
	
	@IBOutlet weak var currentAccountAliasStackView: UIStackView!
	@IBOutlet weak var aliasIcon: UIImageView!
	@IBOutlet weak var aliasTitle: UILabel!
	@IBOutlet weak var aliasSubtitle: UILabel!
	
	@IBOutlet weak var currentAccountRegularStackView: UIStackView!
	@IBOutlet weak var regularIcon: UIImageView!
	@IBOutlet weak var regularTitle: UILabel!
	
	@IBOutlet weak var tableView: UITableView!
	
	public let viewModel = SideMenuViewModel()
	private var cancellable: AnyCancellable?
	
	public weak var homeTabBarController: HomeTabBarController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		scanButton.configuration?.imagePlacement = .trailing
		scanButton.configuration?.imagePadding = 6
		
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
					let _ = ""
					
				case .failure(_, let message):
					self.alert(withTitle: "Error", andMessage: message)
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		viewModel.refresh(animate: true)
		
		let wallet = DependencyManager.shared.selectedWalletMetadata
		let media = TransactionService.walletMedia(forWalletMetadata: wallet, ofSize: .medium)
		
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
	}
	
	@IBAction func showQRTapped(_ sender: Any) {
	}
	
	@IBAction func swapTapped(_ sender: Any) {
	}
}

extension SideMenuViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
	}
}
