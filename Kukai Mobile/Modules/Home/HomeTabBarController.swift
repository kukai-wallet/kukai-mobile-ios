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
//import BeaconCore
//import BeaconBlockchainTezos
import Combine
import OSLog

class HomeTabBarController: UITabBarController {
	
	@IBOutlet weak var sideMenuButton: UIButton!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var sendButton: UIButton!
	
	private var networkChangeCancellable: AnyCancellable?
	private var walletChangeCancellable: AnyCancellable?
	private var activityDetectedCancellable: AnyCancellable?
	private var refreshType: BalanceService.RefreshType = .useCache
	private var topRightMenu = MenuViewController()
	private let scanner = ScanViewController()
	
	private var bag = [AnyCancellable]()
	private var gradientLayers: [CAGradientLayer] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.setupAppearence()
		
		// Load any initial data so we can draw UI immediately without lag
		DependencyManager.shared.balanceService.loadCache()
		
		
		// Setup state listeners that need to be active once the tabview is present. Individual screens will respond as needed
		networkChangeCancellable = DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.setupTzKTAccountListener()
				ActivityViewModel.deleteCache()
				AccountViewModel.setupAccountActivityListener()
				
				self?.refreshType = .refreshEverything
				self?.refresh()
			}
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				DependencyManager.shared.balanceService.deleteAccountCachcedData()
				ActivityViewModel.deleteCache()
				AccountViewModel.setupAccountActivityListener()
				
				self?.updateAccountButton()
				self?.refreshType = .refreshAccountOnly
				self?.refresh()
			}
		
		setupTzKTAccountListener()
		
		
		// Setup buttons
		topRightMenu = menuVCForTopRight()
		sendButton.addAction(UIAction(handler: { [weak self] action in
			self?.topRightMenu.display(attachedTo: self?.sendButton ?? UIButton())
		}), for: .touchUpInside)
		
		
		// Setup Shared UI elements (e.g. account name on tabview navigation bar)
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: self.view.frame.width - (32 + 88 + 20)))
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		sideMenuButton.addConstraint(NSLayoutConstraint(item: sideMenuButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		sideMenuButton.addConstraint(NSLayoutConstraint(item: sideMenuButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44))
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
		
		
		// Start listening for Wallet connect operation requests
		scanner.withTextField = true
		scanner.delegate = self
		setupWCCallbacks()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetState()
		updateAccountButton()
		
		//BeaconService.shared.operationDelegate = self
		//BeaconService.shared.startBeacon(completion: ({ _ in}))
		
		// Loading screen for first time, or when cache has been blitzed, refresh everything
		if !DependencyManager.shared.balanceService.hasFetchedInitialData {
			self.refreshType = .refreshEverything
			refresh()
			
		} else if DependencyManager.shared.balanceService.currencyChanged {
			// currency display only needs a logic update. Can force a screen refresh by simply triggering a cache read, as it will always query the latest from coingecko anyway
			self.refreshType = .useCache
			refresh()
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		for x in gradientLayers {
			x.removeFromSuperlayer()
		}
		
		gradientLayers.append( sideMenuButton.addTitleButtonBorderGradient() )
		gradientLayers.append( sideMenuButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( accountButton.addTitleButtonBorderGradient() )
		gradientLayers.append( accountButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( sendButton.addTitleButtonBorderGradient() )
		gradientLayers.append( sendButton.addTitleButtonBackgroundGradient() )
		gradientLayers.append( self.tabBar.addGradientTabBar(withFrame: CGRect(x: 0, y: 0, width: self.tabBar.bounds.width, height: self.tabBar.bounds.height + (UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0))) )
	}
	
	func setupTzKTAccountListener() {
		activityDetectedCancellable = DependencyManager.shared.tzktClient.$accountDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refreshType = .refreshEverything
				self?.refresh()
			}
	}
	
	
	
	// MARK: UI functions
	
	func setupAppearence() {
		let appearance = UITabBarItem.appearance(whenContainedInInstancesOf: [HomeTabBarController.self])
		appearance.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor(named: "Txt6") ?? .purple,
			NSAttributedString.Key.font: UIFont.custom(ofType: .medium, andSize: 10)
		], for: .normal)
		appearance.setTitleTextAttributes([
			NSAttributedString.Key.foregroundColor: UIColor(named: "TxtB4") ?? .purple,
			NSAttributedString.Key.font: UIFont.custom(ofType: .medium, andSize: 10)
		], for: .selected)
		
		self.tabBar.unselectedItemTintColor = UIColor(named: "BG12")
	}
	
	public func updateAccountButton() {
		let wallet = DependencyManager.shared.selectedWalletMetadata
		
		accountButton.setImage(imageForWallet(wallet: wallet), for: .normal)
		accountButton.setAttributedTitle(textForWallet(wallet: wallet), for: .normal)
		accountButton.titleLabel?.numberOfLines = wallet.type == .social ? 2 : 1
	}
	
	func menuVCForTopRight() -> MenuViewController {
		let firstGroup: [UIAction] = [
			UIAction(title: "Copy Address", image: UIImage(named: "copy"), identifier: nil, handler: { action in
				UIPasteboard.general.string = DependencyManager.shared.selectedWalletAddress
			}),
			UIAction(title: "Show QR Code", image: UIImage(named: "qr-code"), identifier: nil, handler: { [weak self] action in
				self?.alert(withTitle: "Show QR Code", andMessage: "hold your horses, not done yet")
			}),
		]
		
		let secondGroup: [UIAction] = [
			/*UIAction(title: "Send", image: UIImage(named: "send"), identifier: nil, handler: { [weak self] action in
			 self?.sendButtonTapped()
			 }),*/
			UIAction(title: "Swap", image: UIImage(named: "swap"), identifier: nil, handler: { [weak self] action in
				self?.alert(withTitle: "Swap", andMessage: "hold your horses, not done yet")
			}),
		]
		
		let thirdGroup: [UIAction] = [
			UIAction(title: "Get Tez", image: UIImage.unknownToken(), identifier: nil, handler: { [weak self] action in
				self?.alert(withTitle: "Get Tez", andMessage: "hold your horses, not done yet")
			}),
			UIAction(title: "Scan", image: UIImage(named: "scan"), identifier: nil, handler: { [weak self] action in
				guard let self = self else { return }
				self.present(self.scanner, animated: true, completion: nil)
			}),
		]
		
		return MenuViewController(actions: [firstGroup, secondGroup, thirdGroup], sourceViewController: self)
	}
	
	func imageForWallet(wallet: WalletMetadata) -> UIImage? {
		if wallet.type == .social {
			switch wallet.socialType {
				case .apple:
					return UIImage(named: "social-apple")?.resizedImage(Size: CGSize(width: 24, height: 24))
					
				case .google:
					return UIImage(named: "social-google")?.resizedImage(Size: CGSize(width: 24, height: 24))
					
				case .twitter:
					return UIImage(named: "social-twitter")?.resizedImage(Size: CGSize(width: 24, height: 24))
				
				default:
					return UIImage(named: "tezos")?.resizedImage(Size: CGSize(width: 24, height: 24))
			}
		}
		
		return UIImage(named: "tezos")?.resizedImage(Size: CGSize(width: 24, height: 24))
	}
	
	func textForWallet(wallet: WalletMetadata) -> NSAttributedString {
		let attrs1 = [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 12), NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt2")]
		let attrs2 = [NSAttributedString.Key.font: UIFont.custom(ofType: .bold, andSize: 12), NSAttributedString.Key.foregroundColor: UIColor.colorNamed("Txt10")]
		
		if wallet.type == .social {
			var topText = wallet.displayName ?? wallet.address
			let approxPixelsPerCharacter: CGFloat = 10
			let maxCharacters = Int(accountButton.frame.width / approxPixelsPerCharacter)
		
			if topText.count > maxCharacters {
				topText = String(topText.prefix(maxCharacters)) + "..."
			}
			
			let attributedString1 = NSMutableAttributedString(string: "\(topText)\n", attributes: attrs1)
			let attributedString2 = NSMutableAttributedString(string: wallet.address.truncateTezosAddress(), attributes: attrs2)
			attributedString1.append(attributedString2)
			
			return attributedString1
			
		} else {
			let attributedString1 = NSMutableAttributedString(string: wallet.address.truncateTezosAddress(), attributes: attrs1)
			return attributedString1
		}
	}
	
	func refresh() {
	#if DEBUG
		// Avoid excessive loading / spinning while running on simulator. Using Cache and manual pull to refresh is nearly always sufficient and quicker. Can be commented out if need to test
		return
	#else
		let address = DependencyManager.shared.selectedWalletAddress
		self.showLoadingModal()
		self.updateLoadingModalStatusLabel(message: "Refreshing balances")
		
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: address, refreshType: refreshType) { [weak self] error in
			guard let self = self else { return }
			
			self.refreshType = .useCache
			if let e = error {
				self.alert(errorWithMessage: e.description)
			}
			
			self.hideLoadingModal()
			self.updateLoadingModalStatusLabel(message: "")
			DependencyManager.shared.balanceService.currencyChanged = false
		}
	#endif
	}
	
	func sendButtonTapped() {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	
	
	// MARK: - External Wallet Connection
	
	private func processWalletConnectRequest() {
		guard let wcRequest = TransactionService.shared.walletConnectOperationData.request,
			  let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
			  (wcRequest.chainId.absoluteString == "tezos:\(tezosChainName)" || (wcRequest.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
		else {
			let onDevice = "tezos:\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName() ?? "")"
			self.alert(errorWithMessage: "Processing WalletConnect request, request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match")
			return
		}
		
		guard let params = try? wcRequest.params.get(WalletConnectRequestParams.self), let wallet = WalletCacheService().fetchWallet(forAddress: params.account) else {
			self.alert(errorWithMessage: "Processing WalletConnect request, unable to parse response or locate wallet")
			return
		}
		
		TransactionService.shared.walletConnectOperationData.requestParams = params
		self.showLoadingModal { [weak self] in
			self?.processAndShow(withWallet: wallet, requestParams: params)
		}
	}
	
	private func processAndShow(withWallet wallet: Wallet, requestParams: WalletConnectRequestParams) {
		
		// Map all beacon objects to kuaki objects
		let convertedOps = requestParams.kukaiOperations()
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
			guard let estimatedOps = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.alert(errorWithMessage: "Processing WalletConnect request, unable to estimate fees")
				})
				return
			}
			
			self?.processTransactions(estimatedOperations: estimatedOps)
		}
	}
	
	private func processTransactions(estimatedOperations estimatedOps: [KukaiCoreSwift.Operation]) {
		TransactionService.shared.currentTransactionType = .walletConnectOperation
		TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps)
		
		if estimatedOps.first is KukaiCoreSwift.OperationTransaction, let transactionOperation = estimatedOps.first as? KukaiCoreSwift.OperationTransaction {
			
			if transactionOperation.parameters == nil {
				TransactionService.shared.walletConnectOperationData.operationType = .sendXTZ
				
				let xtzAmount = XTZAmount(fromRpcAmount: transactionOperation.amount) ?? .zero()
				TransactionService.shared.walletConnectOperationData.tokenToSend = Token.xtz(withAmount: xtzAmount)
				
			} else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint == "transfer", let token = DependencyManager.shared.balanceService.token(forAddress: transactionOperation.destination) {
				if token.isNFT {
					TransactionService.shared.walletConnectOperationData.operationType = .sendNFT
					TransactionService.shared.walletConnectOperationData.tokenToSend = token.token
					
				} else {
					TransactionService.shared.walletConnectOperationData.operationType = .sendToken
					TransactionService.shared.walletConnectOperationData.tokenToSend = token.token
				}
				
			} else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint != "transfer" {
				TransactionService.shared.walletConnectOperationData.operationType = .callSmartContract
				TransactionService.shared.walletConnectOperationData.entrypointToCall = entrypoint
				
			} else {
				TransactionService.shared.walletConnectOperationData.operationType = .unknown
			}
			
		} else {
			TransactionService.shared.walletConnectOperationData.operationType = .unknown
		}
		
		self.hideLoadingModal(completion: { [weak self] in
			self?.performSegue(withIdentifier: "wallet-connect-operation-approve", sender: nil)
		})
	}
}

extension HomeTabBarController: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		if code == "" { return }
		
		if let walletConnectURI = WalletConnectURI(string: code) {
			pairClient(uri: walletConnectURI)
		}
	}
	
	@MainActor
	private func pairClient(uri: WalletConnectURI) {
		os_log("WC pairing to %@", log: .default, type: .info, uri.absoluteString)
		Task {
			do {
				try await Pair.instance.pair(uri: uri)
			} catch {
				os_log("WC Pairing connect error: %@", log: .default, type: .error, "\(error)")
				self.alert(errorWithMessage: "Unable to pair with: \(uri.absoluteString)")
			}
		}
	}
	
	public func setupWCCallbacks() {
		Sign.instance.sessionRequestPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionRequest in
				os_log("WC sessionRequestPublisher", log: .default, type: .info)
				
				TransactionService.shared.walletConnectOperationData.request = sessionRequest
				
				if sessionRequest.method == "tezos_send" {
					self?.processWalletConnectRequest()
					
				} else if sessionRequest.method == "tezos_sign" {
					self?.performSegue(withIdentifier: "wallet-connect-sign", sender: nil)
					
				} else if sessionRequest.method == "tezos_getAccounts" {
					self?.alert(errorWithMessage: "Unsupported WC method: \(sessionRequest.method)")
					
				} else {
					self?.alert(errorWithMessage: "Recieved unkwnown WalletConnect method request: \(sessionRequest.method)")
				}
				
			}.store(in: &bag)
		
		Sign.instance.sessionProposalPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionProposal in
				os_log("WC sessionProposalPublisher %@", log: .default, type: .info)
				TransactionService.shared.walletConnectOperationData.proposal = sessionProposal
				self?.performSegue(withIdentifier: "wallet-connect-connect", sender: nil)
			}.store(in: &bag)
		
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				os_log("WC sessionSettlePublisher %@", log: .default, type: .info)
				//self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				os_log("WC sessionDeletePublisher %@", log: .default, type: .info)
				//self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
	}
}
















/*
 extension HomeTabBarController: BeaconServiceOperationDelegate {
 
 func operationRequest(requestingAppName: String, operationRequest: OperationTezosRequest) {
 /*guard operationRequest.network.type.rawValue == DependencyManager.shared.currentNetworkType.rawValue else {
  self.alert(errorWithMessage: "Processing Beacon request, request is for a different network than the one currently selected on device. Please check the dApp and apps settings to match sure they match")
  return
  }
  
  guard let wallet = WalletCacheService().fetchWallet(address: operationRequest.sourceAddress) else {
  self.alert(errorWithMessage: "Processing Beacon request, unable to locate wallet: \(operationRequest.sourceAddress)")
  return
  }
  
  self.showLoadingModal { [weak self] in
  self?.processAndShow(withWallet: wallet, operationRequest: operationRequest)
  }
  */
 }
 
 private func processAndShow(withWallet wallet: Wallet, operationRequest: OperationTezosRequest) {
 /*
  // Map all beacon objects to kuaki objects, and apply some logic to avoid having to deal with cumbersome beacon enum structure
  let convertedOps = BeaconService.process(operation: operationRequest, forWallet: wallet)
  
  DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
  guard let estimatedOps = try? result.get() else {
  self?.hideLoadingModal(completion: {
  self?.alert(errorWithMessage: "Processing Beacon request, unable to estimate fees")
  })
  return
  }
  
  self?.processTransactions(estimatedOperations: estimatedOps, operationRequest: operationRequest)
  }
  */
 }
 
 private func processTransactions(estimatedOperations estimatedOps: [KukaiCoreSwift.Operation], operationRequest: OperationTezosRequest) {
 /*TransactionService.shared.currentTransactionType = .beaconOperation
  TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps)
  TransactionService.shared.beaconOperationData.beaconRequest = operationRequest
  
  if estimatedOps.first is KukaiCoreSwift.OperationTransaction, let transactionOperation = estimatedOps.first as? KukaiCoreSwift.OperationTransaction {
  
  if transactionOperation.parameters == nil {
  TransactionService.shared.beaconOperationData.operationType = .sendXTZ
  
  let xtzAmount = XTZAmount(fromRpcAmount: transactionOperation.amount) ?? .zero()
  TransactionService.shared.beaconOperationData.tokenToSend = Token.xtz(withAmount: xtzAmount)
  
  } else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint == "transfer", let token = DependencyManager.shared.balanceService.token(forAddress: transactionOperation.destination) {
  if token.isNFT {
  TransactionService.shared.beaconOperationData.operationType = .sendNFT
  TransactionService.shared.beaconOperationData.tokenToSend = token.token
  
  } else {
  TransactionService.shared.beaconOperationData.operationType = .sendToken
  TransactionService.shared.beaconOperationData.tokenToSend = token.token
  }
  
  } else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint != "transfer" {
  TransactionService.shared.beaconOperationData.operationType = .callSmartContract
  TransactionService.shared.beaconOperationData.entrypointToCall = entrypoint
  
  } else {
  TransactionService.shared.beaconOperationData.operationType = .unknown
  }
  
  } else {
  TransactionService.shared.beaconOperationData.operationType = .unknown
  }
  
  self.hideLoadingModal(completion: { [weak self] in
  self?.performSegue(withIdentifier: "beacon-approve", sender: nil)
  })*/
 }
 }*/
