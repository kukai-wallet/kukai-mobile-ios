//
//  HomeTabBarController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import WalletConnectSign
import WalletConnectPairing
import Combine
import OSLog

public class HomeTabBarController: UITabBarController, UITabBarControllerDelegate {
	
	@IBOutlet weak var sideMenuButton: UIButton!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var scanButton: UIButton!
	
	private var refreshType: BalanceService.RefreshType = .useCache
	private var topRightMenu = MenuViewController()
	private let scanner = ScanViewController()
	private var bag = [AnyCancellable]()
	private var gradientLayers: [CAGradientLayer] = []
	private var highlightedGradient = CAGradientLayer()
	private let sideMenuVc: SideMenuViewController = UIStoryboard(name: "SideMenu", bundle: nil).instantiateInitialViewController() ?? SideMenuViewController()
	
	private var activityAnimationFrames: [UIImage] = []
	private var activityTabBarImageView: UIImageView? = nil
	private var activityAnimationImageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
	
	
	public override func viewDidLoad() {
        super.viewDidLoad()
		self.setupAppearence()
		self.delegate = self
		
		sideMenuVc.homeTabBarController = self
		activityAnimationFrames = UIImage.animationFrames(prefix: "ActivityAni", count: 90)
		
		
		// Load any initial data so we can draw UI immediately without lag
		DependencyManager.shared.balanceService.loadCache()
		
		
		// Setup state listeners that need to be active once the tabview is present. Individual screens will respond as needed
		DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.setupTzKTAccountListener()
				DependencyManager.shared.activityService.deleteCache()
				AccountViewModel.setupAccountActivityListener()
				
				self?.refreshType = .refreshEverything
				self?.refresh()
			}.store(in: &bag)
		
		DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				DependencyManager.shared.balanceService.deleteAccountCachcedData()
				DependencyManager.shared.activityService.deleteCache()
				AccountViewModel.setupAccountActivityListener()
				
				self?.updateAccountButton()
				self?.refreshType = .refreshAccountOnly
				self?.refresh()
			}.store(in: &bag)
		
		setupTzKTAccountListener()
		
		
		// Setup Shared UI elements (e.g. account name on tabview navigation bar)
		let accountButtonWidth = self.view.frame.width - (32 + 88 + 20) // 16 * 2 for left/right gutter, 88 for left/right buttons, 20 for 10px spacing in between
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: accountButtonWidth))
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		sideMenuButton.addConstraint(NSLayoutConstraint(item: sideMenuButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		sideMenuButton.addConstraint(NSLayoutConstraint(item: sideMenuButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		scanButton.addConstraint(NSLayoutConstraint(item: scanButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		scanButton.addConstraint(NSLayoutConstraint(item: scanButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		
		// Start listening for Wallet connect operation requests
		scanner.withTextField = true
		scanner.delegate = self
		WalletConnectService.shared.setup()
		WalletConnectService.shared.delegate = self
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetState()
		updateAccountButton()
		
		// Loading screen for first time, or when cache has been blitzed, refresh everything
		if !DependencyManager.shared.balanceService.hasFetchedInitialData && !DependencyManager.shared.balanceService.isFetchingData {
			self.refreshType = .refreshEverything
			refresh()
			
		} else if DependencyManager.shared.balanceService.currencyChanged {
			// currency display only needs a logic update. Can force a screen refresh by simply triggering a cache read, as it will always query the latest from coingecko anyway
			self.refreshType = .useCache
			refresh()
		}
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		for x in gradientLayers {
			x.removeFromSuperlayer()
		}
		
		gradientLayers.append( sideMenuButton.addTitleButtonBorderGradient() )
		gradientLayers.append( sideMenuButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( scanButton.addTitleButtonBorderGradient() )
		gradientLayers.append( scanButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( accountButton.addTitleButtonBorderGradient() )
		gradientLayers.append( accountButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( self.tabBar.addGradientTabBar(withFrame: CGRect(x: 0, y: 0, width: self.tabBar.bounds.width, height: self.tabBar.bounds.height + (UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0))) )
		
		tabBar(self.tabBar, didSelect: tabBar.selectedItem ?? UITabBarItem())
	}
	
	public func manuallySetSlectedTab(toIndex: Int) {
		self.selectedIndex = toIndex
		tabBar(self.tabBar, didSelect: tabBar.selectedItem ?? UITabBarItem())
	}
	
	public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		let index = self.tabBar.items?.firstIndex(of: item) ?? 0
		let widthPerItem = (self.tabBar.frame.width / CGFloat(self.tabBar.items?.count ?? 1)).rounded()
		let position = CGRect(x: 0 + (widthPerItem * CGFloat(index)), y: -2, width: widthPerItem, height: self.tabBar.bounds.height + (UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0))
		
		if highlightedGradient.frame.width == 0 {
			highlightedGradient = self.tabBar.addTabbarHighlightedBackgroundGradient(rect: position)
			self.tabBar.layer.addSublayer(highlightedGradient)
		} else {
			highlightedGradient.frame.origin.x = 0 + (widthPerItem * CGFloat(index))
		}
	}
	
	func setupTzKTAccountListener() {
		DependencyManager.shared.tzktClient.$accountDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refreshType = .refreshEverything
				self?.refresh()
			}.store(in: &bag)
	}
	
	@IBAction func sideMenuTapped(_ sender: Any) {
		guard let currentWindow = UIApplication.shared.currentWindow else {
			return
		}
		
		let sideMenuWidth = currentWindow.bounds.width - 16
		self.sideMenuVc.view.frame = CGRect(x: sideMenuWidth * -1, y: 0, width: sideMenuWidth, height: currentWindow.bounds.height)
		currentWindow.addSubview(sideMenuVc.view)
		
		UIView.animate(withDuration: 0.3, delay: 0) { [weak self] in
			self?.sideMenuVc.view.frame = CGRect(x: 0, y: 0, width: sideMenuWidth, height: currentWindow.bounds.height)
		}
	}
	
	@IBAction func scanTapped(_ sender: Any) {
		openScanner()
	}
	
	public func openScanner() {
		self.present(scanner, animated: true)
	}
	
	
	
	
	
	// MARK: UI functions
	
	func setupAppearence() {
		let appearance = UITabBarItem.appearance(whenContainedInInstancesOf: [HomeTabBarController.self])
		appearance.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor(named: "BG10") ?? .purple,
			NSAttributedString.Key.font: UIFont.custom(ofType: .medium, andSize: 10)
		], for: .normal)
		appearance.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor(named: "BGB6") ?? .purple,
			NSAttributedString.Key.font: UIFont.custom(ofType: .medium, andSize: 10)
		], for: .selected)
		
		self.tabBar.shadowImage = nil
		self.tabBar.tintColor = UIColor(named: "BGB6")
		self.tabBar.unselectedItemTintColor = UIColor(named: "BG10")
	}
	
	func startActivityAnimation() {
		
		let sorted = self.tabBar.subviews.sorted { lhs, rhs in
			return lhs.frame.origin.x < rhs.frame.origin.x
		}
		
		let activitySubview = sorted[sorted.count-2]
		guard let activityImageView = activitySubview.subviews.first as? UIImageView else { return }
		
		activityTabBarImageView = activityImageView
		
		activitySubview.addSubview(activityAnimationImageView)
		activityAnimationImageView.frame = activityImageView.frame
		activityAnimationImageView.animationImages = activityAnimationFrames
		activityAnimationImageView.animationDuration = 3
		
		activityImageView.isHidden = true
		activityAnimationImageView.isHidden = false
		activityAnimationImageView.startAnimating()
	}
	
	func stopActivityAnimation(success: Bool) {
		activityAnimationImageView.stopAnimating()
		activityAnimationImageView.isHidden = true
		activityTabBarImageView?.isHidden = false
	}
	
	public func updateAccountButton() {
		guard let wallet = DependencyManager.shared.selectedWalletMetadata else { return }
		
		let media = TransactionService.walletMedia(forWalletMetadata: wallet, ofSize: .size_26)
		
		accountButton.setImage(media.image, for: .normal)
		accountButton.setAttributedTitle(textForWallet(title: media.title, subtitle: media.subtitle), for: .normal)
		accountButton.titleLabel?.numberOfLines = wallet.type == .social ? 2 : 1
	}
	
	func textForWallet(title: String, subtitle: String?) -> NSAttributedString {
		
		if let subtitle = subtitle {
			let attrs1 = [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 12), NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2")]
			let attrs2 = [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 12), NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt10")]
			
			var topText = title
			let approxPixelsPerCharacter: CGFloat = 5
			let maxCharacters = Int(accountButton.frame.width / approxPixelsPerCharacter)
			
			if topText.count > maxCharacters {
				topText = String(topText.prefix(maxCharacters)) + "..."
			}
			
			let attributedString1 = NSMutableAttributedString(string: "\(topText)\n", attributes: attrs1)
			let attributedString2 = NSMutableAttributedString(string: subtitle, attributes: attrs2)
			attributedString1.append(attributedString2)
			
			return attributedString1
			
		} else {
			let attrs1 = [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 16), NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2")]
			let attributedString1 = NSMutableAttributedString(string: title, attributes: attrs1)
			return attributedString1
		}
	}
	
	func refresh() {
	//#if DEBUG
	//	// Avoid excessive loading / spinning while running on simulator. Using Cache and manual pull to refresh is nearly always sufficient and quicker. Can be commented out if need to test
	//	return
	//#else
		guard let address = DependencyManager.shared.selectedWalletAddress else { return }
		
		let wasActivityPending = DependencyManager.shared.activityService.pendingTransactionGroups.count > 0
		
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address, refreshType: refreshType) { [weak self] error in
			guard let self = self else { return }
			
			self.refreshType = .useCache
			if let e = error {
				self.alert(errorWithMessage: e.description)
			}
			
			if wasActivityPending && DependencyManager.shared.activityService.pendingTransactionGroups.count == 0 {
				self.stopActivityAnimation(success: true)
			}
			
			DependencyManager.shared.balanceService.currencyChanged = false
		}
	//#endif
	}
	
	func sendButtonTapped() {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
}



// MARK: Scanner

extension HomeTabBarController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		if code == "" { return }
		
		if let walletConnectURI = WalletConnectURI(string: code) {
			WalletConnectService.shared.pairClient(uri: walletConnectURI)
		}
	}
}



// MARK: Wallet Connect

extension HomeTabBarController: WalletConnectServiceDelegate {
	
	public func pairRequested() {
		self.performSegue(withIdentifier: "wallet-connect-pair", sender: nil)
	}
	
	public func signRequested() {
		// self.performSegue(withIdentifier: "wallet-connect-send-token", sender: nil)
	}
	
	public func processingIncomingOperations() {
		self.showLoadingModal()
	}
	
	public func processedOperations(ofType: WalletConnectOperationType) {
		self.hideLoadingModal { [weak self] in
			switch ofType {
				case .sendToken:
					self?.performSegue(withIdentifier: "wallet-connect-send-token", sender: nil)
					
				case .sendNft:
					self?.performSegue(withIdentifier: "wallet-connect-send-nft", sender: nil)
					
				case .contractCall:
					self?.performSegue(withIdentifier: "wallet-connect-send-token", sender: nil)
			}
		}
	}
	
	public func provideAccountList() {
		WalletConnectService.shared.respondWithAccounts()
	}
	
	public func error(message: String?, error: Error?) {
		self.hideLoadingModal { [weak self] in
			
			if let m = message {
				self?.alert(errorWithMessage: m)
				
			} else if let e = error {
				self?.alert(errorWithMessage: "\(e)")
				
			} else {
				self?.alert(errorWithMessage: "Unknown Wallet Connect error occured")
			}
		}
	}
}
