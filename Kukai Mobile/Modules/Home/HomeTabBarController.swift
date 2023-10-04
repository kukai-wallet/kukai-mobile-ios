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
	private let scanner = ScanViewController()
	private var bag = [AnyCancellable]()
	private var gradientLayers: [CAGradientLayer] = []
	private var highlightedGradient = CAGradientLayer()
	private var sideMenuVc: SideMenuViewController? = nil
	
	private var activityAnimationFrames: [UIImage] = []
	private var activityTabBarImageView: UIImageView? = nil
	private var activityAnimationImageView: UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
	private var activityAnimationInProgress = false
	
	public var didApprovePairing = false
	public var didApproveSigning = false
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
		DependencyManager.shared.balanceService.loadCache(address: DependencyManager.shared.selectedWalletAddress)
		
		
		// Setup state listeners that need to be active once the tabview is present. Individual screens will respond as needed
		DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				guard let address = DependencyManager.shared.selectedWalletAddress else { return }
				
				DispatchQueue.global(qos: .background).async {
					DependencyManager.shared.balanceService.loadCache(address: address)
					
					DispatchQueue.main.async {
						DependencyManager.shared.addressLoaded = address
						self?.updateAccountButton()
						
						AccountViewModel.setupAccountActivityListener() // trigger reconnection, so that we switch networks
						
						self?.setupTzKTAccountListener()
						self?.stopActivityAnimation(success: false)
						self?.refreshType = .useCacheIfNotStale
						self?.refresh(addresses: nil)
					}
				}
			}.store(in: &bag)
		
		DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				guard let address = DependencyManager.shared.selectedWalletAddress else { return }
				
				DispatchQueue.global(qos: .background).async {
					DependencyManager.shared.balanceService.loadCache(address: address)
					
					DispatchQueue.main.async {
						DependencyManager.shared.addressLoaded = address
						
						self?.refreshType = .useCacheIfNotStale
						self?.refresh(addresses: nil)
					}
				}
			}.store(in: &bag)
		
		DependencyManager.shared.activityService.$addressesWithPendingOperation
			.dropFirst()
			.sink { [weak self] addresses in
				if addresses.count > 0 {
					self?.startActivityAnimationIfNecessary(addressesToBeRefreshed: addresses)
				} else {
					self?.stopActivityAnimationIfNecessary()
				}
			}.store(in: &bag)
		
		DependencyManager.shared.balanceService.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				if address == DependencyManager.shared.selectedWalletAddress {
					DispatchQueue.global(qos: .background).async {
						DependencyManager.shared.balanceService.loadCache(address: address)
						
						DispatchQueue.main.async {
							self?.updateAccountButton()
							DependencyManager.shared.addressRefreshed = address
						}
					}
				}
				
			}.store(in: &bag)
		
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { [weak self] _ in
			self?.refreshType = .refreshEverything
			self?.refresh(addresses: nil)
		}.store(in: &bag)
		
		ThemeManager.shared.$themeDidChange
			.dropFirst()
			.sink { [weak self] _ in
				(UIApplication.shared.delegate as? AppDelegate)?.setAppearenceProxies()
				self?.view.setNeedsDisplay()
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
	
	@objc private func closeSideMenu() {
		sideMenuVc?.closeTapped(self)
	}
	
	public func refreshSideMenu() {
		sideMenuVc?.viewModel.refresh(animate: true)
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetAllState()
		updateAccountButton()
		
		// Loading screen for first time, or when cache has been blitzed, refresh everything
		let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
		if DependencyManager.shared.balanceService.isCacheStale(forAddress: selectedAddress) && DependencyManager.shared.balanceService.addressesWaitingToBeRefreshed.count == 0 {
			self.refreshType = .useCacheIfNotStale
			refresh(addresses: nil)
		}
		
		// Check if we need to start or stop the activity animation
		let pendingAddresses = DependencyManager.shared.activityService.addressesWithPendingOperation
		if pendingAddresses.count > 0, let selectedAddress = DependencyManager.shared.selectedWalletAddress, pendingAddresses.contains([selectedAddress]) {
			startActivityAnimationIfNecessary(addressesToBeRefreshed: DependencyManager.shared.activityService.addressesWithPendingOperation)
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
			.sink { [weak self] addresses in
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
	
	public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination.presentationController as? UISheetPresentationController {
			dest.delegate = self
		}
		
		if let vc = segue.destination as? WalletConnectPairViewController {
			didApprovePairing = false
			vc.presenter = self
			
		} else if let vc = segue.destination as? WalletConnectSignViewController {
			didApproveSigning = false
			vc.presenter = self
		}
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
		if !self.activityAnimationInProgress {
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
		
		if records.count == 0 {
			records.append(BalanceService.FetchRequestRecord(address: DependencyManager.shared.selectedWalletAddress ?? "", type: refreshType))
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
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			self.performSegue(withIdentifier: "wallet-connect-sign", sender: nil)
		}
	}
	
	public func processingIncomingOperations() {
		self.showLoadingView()
	}
	
	public func processedOperations(ofType: WalletConnectOperationType) {
		self.loadingViewHideActivity()
		
		if self.presentedViewController == nil {
			switch ofType {
				case .sendToken:
					self.performSegue(withIdentifier: "wallet-connect-send-token", sender: nil)
					
				case .sendNft:
					self.performSegue(withIdentifier: "wallet-connect-send-nft", sender: nil)
					
				case .contractCall:
					self.performSegue(withIdentifier: "wallet-connect-contract", sender: nil)
			}
		}
	}
	
	public func provideAccountList() {
		WalletConnectService.shared.respondWithAccounts()
	}
	
	public func error(message: String?, error: Error?) {
		self.hideLoadingView()
			
		if let m = message {
			var message = "\(m)"
			if let e = error as? KukaiError {
				message += ". Due to error: \(e.description)"
			} else if let e = error {
				message += ". Due to error: \(e.localizedDescription)"
			}
			
			self.windowError(withTitle: "Error", description: message)
			self.respondOnReject(withMessage: m)
			
		} else if let e = error as? KukaiError {
			self.windowError(withTitle: "Error", description: e.description)
			self.respondOnReject(withMessage: "Error: \(e.description)")
			
		} else if let e = error{
			self.windowError(withTitle: "Error", description: e.localizedDescription)
			self.respondOnReject(withMessage: "Error: \(e.localizedDescription)")
			
		} else {
			self.windowError(withTitle: "Error", description: "Unknown Wallet Connect error occured")
			self.respondOnReject(withMessage: "Unknown error occurred")
		}
	}
	
	@MainActor
	private func respondOnReject(withMessage: String) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Reject Session error: Unable to find request", log: .default, type: .error)
			return
		}
		
		os_log("WC Reject Request: %@", log: .default, type: .info, "\(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 0, message: withMessage)))
				TransactionService.shared.resetWalletConnectState()
			} catch {
				os_log("WC Reject Session error: %@", log: .default, type: .error, "\(error)")
			}
		}
	}
}


// MARK: - UISheetPresentationControllerDelegate

extension HomeTabBarController: UISheetPresentationControllerDelegate {
	
	public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
		if let _ = presentationController.presentedViewController as? WalletConnectPairViewController, !didApprovePairing {
			didApprovePairing = false
			
			guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
				return
			}
			
			self.showLoadingView()
			do {
				try WalletConnectService.reject(proposalId: proposal.id, reason: .userRejected)
				self.hideLoadingView()
				
			} catch (let error) {
				self.hideLoadingView()
				self.windowError(withTitle: "Error", description: error.localizedDescription)
			}
			
		} else if let _ = presentationController.presentedViewController as? WalletConnectSignViewController, !didApproveSigning {
			didApproveSigning = false
			
			guard let request = TransactionService.shared.walletConnectOperationData.request else {
				return
			}
			
			self.showLoadingView()
			do {
				try WalletConnectService.reject(topic: request.topic, requestId: request.id)
				self.hideLoadingView()
				
			} catch (let error) {
				self.hideLoadingView()
				self.windowError(withTitle: "Error", description: error.localizedDescription)
			}
		}
	}
}
