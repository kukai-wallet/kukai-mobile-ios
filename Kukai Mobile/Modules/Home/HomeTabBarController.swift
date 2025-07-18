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
	
	@IBOutlet weak var sideMneuButtonContainer: UIBarButtonItem!
	@IBOutlet weak var sideMenuButton: UIButton!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var scanButtonContainer: UIBarButtonItem!
	@IBOutlet weak var scanButton: UIButton!
	
	private var refreshType: BalanceService.RefreshType = .useCache
	private let scanner = ScanViewController()
	private var bag = [AnyCancellable]()
	private var gradientLayers: [CAGradientLayer] = []
	private var highlightedGradient = CAGradientLayer()
	private var sideMenuVc: SideMenuViewController? = nil
	
	private var activityAnimationFrames: [UIImage] = []
	private var activityTabBarImageView: UIImageView? = nil
	private var activityAnimationImageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
	private var activityAnimationInProgress = false
	private var supressAutoRefreshError = false // Its jarring to the user if we auto refresh the balances sliently without interaction, and then display an error about a request timing out
	private var activityAnimationExperimentalTimer: Timer? = nil // Timer for use in experimental mode to replace tzkt account change monitoring
	private var walletConnectOperationTypeOnResume: WalletConnectOperationType? = nil
	
	public var sideMenuTintView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
	
	
	public override func viewDidLoad() {
        super.viewDidLoad()
		self.setupAppearence()
		self.delegate = self
		
		sideMenuTintView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeSideMenu)))
		sideMenuTintView.isUserInteractionEnabled = true
		
		sideMenuButton.accessibilityIdentifier = "home-button-side"
		accountButton.accessibilityIdentifier = "home-button-account"
		scanButton.accessibilityIdentifier = "home-button-scan"
		activityAnimationImageView.accessibilityIdentifier = "home-animation-imageview"
		activityAnimationImageView.accessibilityValue = "end"
		
		activityAnimationFrames = UIImage.animationFrames(prefix: "ActivityAni", count: 90)
		
		
		// Load any initial data so we can draw UI immediately without lag
		if !DependencyManager.shared.loginActive {
			DependencyManager.shared.balanceService.loadCache(address: DependencyManager.shared.selectedWalletAddress, completion: nil)
		}

		
		// Setup state listeners that need to be active once the tabview is present. Individual screens will respond as needed
		DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				guard let address = DependencyManager.shared.selectedWalletAddress else { return }
				
				DependencyManager.shared.balanceService.loadCache(address: address) {
					DependencyManager.shared.addressLoaded = address
					self?.updateAccountButton()
					
					AccountViewModel.setupAccountActivityListener() // trigger reconnection, so that we switch networks
					
					self?.setupTzKTAccountListener()
					self?.stopActivityAnimation(success: false)
					self?.refreshType = .useCacheIfNotStale
					self?.refresh(addresses: nil)
				}
			}.store(in: &bag)
		
		DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				guard let address = DependencyManager.shared.selectedWalletAddress else { return }
				
				DependencyManager.shared.balanceService.loadCache(address: address) {
					// Check if we need to start or stop the activity animation
					let pendingAddresses = DependencyManager.shared.activityService.addressesWithPendingOperation
					if pendingAddresses.contains([address]) {
						self?.startActivityAnimationIfNecessary(addressesToBeRefreshed: pendingAddresses)
					} else {
						self?.stopActivityAnimationIfNecessary()
					}
					
					DependencyManager.shared.addressLoaded = address
					
					self?.refreshType = .useCacheIfNotStale
					self?.refresh(addresses: nil)
				}
			}.store(in: &bag)
		
		DependencyManager.shared.activityService.$addressesWithPendingOperation
			.dropFirst()
			.sink { [weak self] addresses in
				guard let address = DependencyManager.shared.selectedWalletAddress else { return }
				
				if addresses.contains([address]) {
					self?.startActivityAnimationIfNecessary(addressesToBeRefreshed: addresses)
				} else {
					self?.stopActivityAnimationIfNecessary()
				}
			}.store(in: &bag)
		
		DependencyManager.shared.balanceService.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				
				if DependencyManager.shared.appUpdateService.isRequiredUpdate {
					self?.displayUpdateRequired()
				}
				
				if address == DependencyManager.shared.selectedWalletAddress {
					DependencyManager.shared.balanceService.loadCache(address: address) {
						self?.updateAccountButton()
						DependencyManager.shared.addressRefreshed = address
					}
				}
				
			}.store(in: &bag)
		
		DependencyManager.shared.balanceService.$addressErrored
			.dropFirst()
			.sink { [weak self] obj in
				
				if let obj = obj, obj.address == DependencyManager.shared.selectedWalletAddress {
					
					if self?.supressAutoRefreshError == true {
						self?.supressAutoRefreshError = false
					} else {
						DispatchQueue.main.async {
							self?.windowError(withTitle: "error".localized(), description: obj.error.description)
						}
					}
				}
			}.store(in: &bag)
		
		
		
		// If we enter foreground without login, check for refresh needs
		// else when login dismisses, check for refresh needs
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			if !DependencyManager.shared.loginActive {
				AccountViewModel.reconnectAccountActivityListenerIfNeeded()
				self?.supressAutoRefreshError = true
				self?.refreshType = .refreshEverything
				self?.refresh(addresses: nil)
			}
		}.store(in: &bag)
		
		DependencyManager.shared.$loginActive
			.dropFirst()
			.sink { [weak self] active in
				
				// Debugging issue where `active` seems to be an old value sometimes
				if DependencyManager.shared.loginActive {
					AccountViewModel.reconnectAccountActivityListenerIfNeeded()
					self?.supressAutoRefreshError = true
					self?.refreshType = .refreshEverything
					self?.refresh(addresses: nil)
					
					if let type = self?.walletConnectOperationTypeOnResume {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							self?.processedOperations(ofType: type)
							self?.walletConnectOperationTypeOnResume = nil
						}
					}
						
				}
			}.store(in: &bag)
		
		
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				(UIApplication.shared.delegate as? AppDelegate)?.setAppearenceProxies()
				self?.view.setNeedsLayout()
			}.store(in: &bag)
		
		setupTzKTAccountListener()
		
		
		// Setup Shared UI elements (e.g. account name on tabview navigation bar)
		let accountButtonWidth = self.view.frame.width - (32 + 88 + 20) // 16 * 2 for left/right gutter, 88 for left/right buttons, 20 for 10px spacing in between
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: accountButtonWidth))
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		NSLayoutConstraint.activate([
			sideMenuButton.heightAnchor.constraint(equalToConstant: 44),
			sideMenuButton.widthAnchor.constraint(equalToConstant: 44),
			scanButton.heightAnchor.constraint(equalToConstant: 44),
			scanButton.widthAnchor.constraint(equalToConstant: 44)
		])
		
		
		// Start listening for Wallet connect operation requests
		scanner.withTextField = true
		scanner.delegate = self
		WalletConnectService.shared.delegate = self
	}
	
	@objc private func closeSideMenu() {
		sideMenuVc?.closeTapped(self)
	}
	
	public func runWatchWalletChecks() {
		if DependencyManager.shared.selectedWalletMetadata?.isWatchOnly == true {
			scanButton.isEnabled = false
		} else {
			scanButton.isEnabled = true
		}
	}
	
	public func refreshSideMenu() {
		sideMenuVc?.viewModel.refresh(animate: true)
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
			
			// Both iPad and Mac, as mac is running "Designed for iPad"
			traitOverrides.horizontalSizeClass = .unspecified
			
			
			if ProcessInfo.processInfo.isiOSAppOnMac {
				/// Fix for macOS Sequoia: without it, the tabs
				/// appear twice and the view crashes regularly.
						
				/// Hides the top tabs
				self.mode = .tabSidebar
				self.sidebar.isHidden = true
			}
		}
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		updateAccountButton()
		runWatchWalletChecks()
		
		// Loading screen for first time, or when cache has been blitzed, refresh everything
		let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		if !DependencyManager.shared.loginActive, DependencyManager.shared.balanceService.isCacheStale(forAddress: selectedAddress) && DependencyManager.shared.balanceService.addressesWaitingToBeRefreshed.count == 0 {
			self.refreshType = .useCacheIfNotStale
			refresh(addresses: nil)
		}
		
		// Check if we need to start or stop the activity animation
		let pendingAddresses = DependencyManager.shared.activityService.addressesWithPendingOperation
		if pendingAddresses.contains([selectedAddress]) {
			startActivityAnimationIfNecessary(addressesToBeRefreshed: pendingAddresses)
		} else {
			stopActivityAnimationIfNecessary()
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
		
		
		highlightedGradient.removeFromSuperlayer()
		highlightedGradient = CAGradientLayer()
		
		let widthPerItem = (self.tabBar.frame.width / CGFloat(self.tabBar.items?.count ?? 1)).rounded()
		let position = CGRect(x: 0, y: -2, width: widthPerItem, height: self.tabBar.bounds.height + (UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0))
		
		highlightedGradient = self.tabBar.addTabbarHighlightedBackgroundGradient(rect: position)
		self.tabBar.layer.addSublayer(highlightedGradient)
		
		tabBar(self.tabBar, didSelect: tabBar.selectedItem ?? UITabBarItem())
	}
	
	public func manuallySetSlectedTab(toIndex: Int) {
		self.selectedIndex = toIndex
		tabBar(self.tabBar, didSelect: tabBar.selectedItem ?? UITabBarItem())
	}
	
	public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
		let index = self.tabBar.items?.firstIndex(of: item) ?? 0
		let widthPerItem = (self.tabBar.frame.width / CGFloat(self.tabBar.items?.count ?? 1)).rounded()
		
		highlightedGradient.frame.origin.x = (0 + (widthPerItem * CGFloat(index)))
	}
	
	func setupTzKTAccountListener() {
		DependencyManager.shared.tzktClient.$accountDidChange
			.dropFirst()
			.sink { [weak self] addresses in
				Logger.app.info("$accountDidChange Refreshing everything for \(addresses)")
				self?.refreshType = .refreshEverything
				self?.refresh(addresses: addresses)
			}.store(in: &bag)
	}
	
	@IBAction func sideMenuTapped(_ sender: Any) {
		guard let currentWindow = UIApplication.shared.currentWindow else {
			return
		}
		
		sideMenuVc?.view.removeFromSuperview()
		sideMenuVc = nil
		
		sideMenuVc = UIStoryboard(name: "SideMenu", bundle: nil).instantiateInitialViewController() ?? SideMenuViewController()
		sideMenuVc?.homeTabBarController = self
		sideMenuTintView.frame = currentWindow.bounds
		sideMenuTintView.backgroundColor = .colorNamed("TintGeneral")
		sideMenuTintView.alpha = 0
		
		
		let sideMenuWidth = currentWindow.bounds.width - 50
		self.sideMenuVc?.view.frame = CGRect(x: sideMenuWidth * -1, y: 0, width: sideMenuWidth, height: currentWindow.bounds.height)
		currentWindow.addSubview(sideMenuTintView)
		currentWindow.addSubview(sideMenuVc?.view ?? UIView())
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.sideMenuTintView.alpha = 1
			self?.sideMenuVc?.view.frame = CGRect(x: 0, y: 0, width: sideMenuWidth, height: currentWindow.bounds.height)
			
		} completion: { _ in
			DependencyManager.shared.sideMenuOpen = true
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
		activityAnimationInProgress = true
		
		let sorted = self.tabBar.subviews.sorted { lhs, rhs in
			return lhs.frame.origin.x < rhs.frame.origin.x
		}
		
		if activityAnimationImageView.superview == nil {
			let activitySubview = sorted[sorted.count-2]
			guard let activityImageView = activitySubview.subviews.first as? UIImageView else { return }
			activityTabBarImageView = activityImageView
			activitySubview.addSubview(activityAnimationImageView)
		}
		
		activityAnimationImageView.frame = activityTabBarImageView?.frame ?? CGRect(x: 0, y: 0, width: 24, height: 24)
		activityAnimationImageView.animationImages = activityAnimationFrames
		activityAnimationImageView.animationDuration = 3
		
		activityTabBarImageView?.isHidden = true
		activityAnimationImageView.isHidden = false
		activityAnimationImageView.accessibilityValue = "start"
		activityAnimationImageView.startAnimating()
	}
	
	func startActivityAnimationIfNecessary(addressesToBeRefreshed addresses: [String]) {
		if !self.activityAnimationInProgress, let selectedAddress = DependencyManager.shared.selectedWalletAddress, addresses.contains([selectedAddress]) {
			
			// If RPC only mode, setup manual timer to assume transaction made it into the next block
			if DependencyManager.shared.isRpcOnlyMode {
				let seconds = DependencyManager.shared.tezosNodeClient.networkConstants?.secondsBetweenBlocks() ?? 8
				activityAnimationExperimentalTimer = Timer.scheduledTimer(withTimeInterval: Double(seconds), repeats: false, block: { [weak self] _ in
					Logger.app.info("Manual RPC only refresh trigger for address: \(addresses)")
					self?.refreshType = .refreshEverything
					self?.refresh(addresses: addresses)
				})
			}
			
			self.startActivityAnimation()
		}
	}
	
	func stopActivityAnimation(success: Bool) {
		DispatchQueue.main.async { [weak self] in
			self?.activityAnimationInProgress = false
			
			self?.activityAnimationImageView.stopAnimating()
			self?.activityAnimationImageView.isHidden = true
			self?.activityAnimationImageView.accessibilityValue = "end"
			self?.activityTabBarImageView?.isHidden = false
		}
	}
	
	func stopActivityAnimationIfNecessary() {
		if self.activityAnimationInProgress {
			self.activityAnimationExperimentalTimer?.invalidate()
			self.activityAnimationExperimentalTimer = nil
			self.stopActivityAnimation(success: true)
		}
	}
	
	public func updateAccountButton() {
		DispatchQueue.main.async { [weak self] in
			guard let wallet = DependencyManager.shared.selectedWalletMetadata else { return }
			
			let media = TransactionService.walletMedia(forWalletMetadata: wallet, ofSize: .size_26)
			
			self?.accountButton.setImage(media.image, for: .normal)
			self?.accountButton.setAttributedTitle(self?.textForWallet(title: media.title, subtitle: media.subtitle), for: .normal)
			self?.accountButton.titleLabel?.numberOfLines = (media.subtitle != nil) ? 2 : 1
		}
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
	
	func refresh(addresses: [String]?) {
		var records: [BalanceService.FetchRequestRecord] = []
		for address in addresses ?? [] {
			records.append(BalanceService.FetchRequestRecord(address: address, type: refreshType))
		}
		
		
		// If no address is passed in, thats short hand for refreshing the current address. However refreshing the current address will simply trigger an expensive cacheLoad if the data is not stale
		// Until we move to middleware, simply add another check here. If its not stale, just skip and avoid the reload
		if records.count == 0 {
			let currentAddress = DependencyManager.shared.selectedWalletAddress ?? ""
			if DependencyManager.shared.balanceService.account.walletAddress == currentAddress, !DependencyManager.shared.balanceService.isCacheStale(forAddress: currentAddress) {
				// Do nothing for now
				return
				
			} else {
				records.append(BalanceService.FetchRequestRecord(address: DependencyManager.shared.selectedWalletAddress ?? "", type: refreshType))
			}
		}
		
		DependencyManager.shared.balanceService.fetch(records: records)
	}
	
	func refreshAllWallets() {
		let addresses = DependencyManager.shared.walletList.addresses()
		refresh(addresses: addresses)
	}
	
	func sendButtonTapped() {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	func displayUpdateRequired() {
		self.performSegue(withIdentifier: "app-update-required", sender: nil)
	}
}



// MARK: Scanner

extension HomeTabBarController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		if code == "" { return }
		
		if let walletConnectURI = try? WalletConnectURI(uriString: code) {
			WalletConnectService.shared.pairClient(uri: walletConnectURI)
		}
	}
}



// MARK: Wallet Connect

extension HomeTabBarController: WalletConnectServiceDelegate {
	
	public func connectionStatusChanged(status: SocketConnectionStatus) {
		
	}
	
	public func pairRequested() {
		if self.presentedViewController == nil {
			self.performSegue(withIdentifier: "wallet-connect-pair", sender: nil)
		} else {
			WalletConnectService.rejectCurrentProposal(completion: nil)
			self.windowError(withTitle: "error".localized(), description: "error-wc2-cant-open-more-modals".localized())
		}
	}
	
	public func signRequested() {
		self.loadingViewHideActivityAndFade(withDuration: 0.5)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			if self?.presentedViewController == nil {
				self?.performSegue(withIdentifier: "wallet-connect-sign", sender: nil)
				
			} else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				self?.windowError(withTitle: "error".localized(), description: "error-wc2-cant-open-more-modals".localized())
			}
		}
	}
	
	public func processingIncomingOperations() {
		DispatchQueue.main.async {
			self.showLoadingView()
		}
	}
	
	public func processingIncomingDone() {
		DispatchQueue.main.async {
			self.hideLoadingView()
		}
	}
	
	public func processedOperations(ofType: WalletConnectOperationType) {
		self.loadingViewHideActivityAndFade(withDuration: 0.5)
		
		guard !DependencyManager.shared.loginActive else {
			walletConnectOperationTypeOnResume = ofType
			return
		}
		
		if self.presentedViewController == nil {
			switch ofType {
				case .sendToken:
					self.performSegue(withIdentifier: "wallet-connect-send-token", sender: nil)
					
				case .sendNft:
					self.performSegue(withIdentifier: "wallet-connect-send-nft", sender: nil)
					
				case .batch:
					self.performSegue(withIdentifier: "wallet-connect-batch", sender: nil)
					
				case .delegate:
					self.performSegue(withIdentifier: "wallet-connect-delegate", sender: nil)
					
				case .stake:
					self.performSegue(withIdentifier: "wallet-connect-stake", sender: nil)
					
				case .generic:
					self.performSegue(withIdentifier: "wallet-connect-generic", sender: nil)
			}
		} else {
			WalletConnectService.rejectCurrentRequest(completion: nil)
			self.windowError(withTitle: "error".localized(), description: "error-wc2-cant-open-more-modals".localized())
		}
	}
	
	public func error(message: String?, error: Error?) {
		Logger.app.error("WC2 error message: \(message) - error: \(error)")
		self.hideLoadingView()
			
		if let m = message {
			var message = "\(m)"
			if let e = error as? KukaiError {
				message += ". \(e.description)"
			} else if let e = error {
				message += ". \(e.localizedDescription)"
			}
			
			self.windowError(withTitle: "error".localized(), description: message)
			
		} else if let e = error as? KukaiError {
			self.windowError(withTitle: "error".localized(), description: e.description)
			
		} else if let e = error{
			self.windowError(withTitle: "error".localized(), description: e.localizedDescription)
			
		} else {
			self.windowError(withTitle: "error".localized(), description: "error-unknwon-wc2".localized())
		}
	}
}
