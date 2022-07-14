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
import BeaconCore
import BeaconBlockchainTezos
import OSLog

class HomeTabBarController: UITabBarController {
	
	@IBOutlet weak var accountButtonParent: UIBarButtonItem!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var sendButton: UIButton!
	
	private var walletChangeCancellable: AnyCancellable?
	private var bag = [AnyCancellable]()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateAccountButton()
			}
		
		accountButton.titleLabel?.numberOfLines = 2
		accountButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
		accountButton.addConstraint(NSLayoutConstraint(item: accountButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: (self.view.frame.width * 0.75)))
		
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 34))
		sendButton.addConstraint(NSLayoutConstraint(item: sendButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 34))
		
		
		// Start listening for Wallet connect operation requests
		Sign.instance.sessionRequestPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionRequest in
				os_log("WC sessionRequestPublisher", log: .default, type: .info)
				
				TransactionService.shared.walletConnectOperationData.request = sessionRequest
				
				if sessionRequest.method == "tezos_sendOperations" {
					self?.processWalletConnectRequest()
					
				} else if sessionRequest.method == "tezos_signExpression" {
					self?.alert(errorWithMessage: "Unsupported WC method: \(sessionRequest.method)")
					
				} else if sessionRequest.method == "tezos_getAccounts" {
					self?.alert(errorWithMessage: "Unsupported WC method: \(sessionRequest.method)")
					
				} else {
					self?.alert(errorWithMessage: "Recieved unkwnown WalletConnect method request: \(sessionRequest.method)")
				}
				
			}.store(in: &bag)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		TransactionService.shared.resetState()
		updateAccountButton()
		
		
		BeaconService.shared.operationDelegate = self
		BeaconService.shared.startBeacon(completion: ({ _ in}))
	}
	
	public func updateAccountButton() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			return
		}
		
		accountButton.setImage((wallet.type == .social) ? UIImage(systemName: "xmark.octagon") : UIImage(), for: .normal)
		accountButton.setTitle("Wallet Type: \(wallet.type.rawValue)\n\(wallet.address)", for: .normal)
	}
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "send", sender: nil)
	}
	
	private func processWalletConnectRequest() {
		guard let wcRequest = TransactionService.shared.walletConnectOperationData.request,
			  let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
			  (wcRequest.chainId.absoluteString == "tezos:\(tezosChainName)" || (wcRequest.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
		else {
			let onDevice = "tezos:\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName() ?? "")"
			self.alert(errorWithMessage: "Processing WalletConnect request, request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match")
			return
		}
		
		guard let params = try? wcRequest.params.get(WalletConnectRequestParams.self), let wallet = WalletCacheService().fetchWallet(address: params.account) else {
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
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, withWallet: wallet) { [weak self] result in
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
		TransactionService.shared.walletConnectOperationData.estimatedOperations = estimatedOps
		
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
			self?.performSegue(withIdentifier: "wallet-connect-approve", sender: nil)
		})
	}
}

extension HomeTabBarController: BeaconServiceOperationDelegate {
	
	func operationRequest(requestingAppName: String, operationRequest: OperationTezosRequest) {
		guard operationRequest.network.type.rawValue == DependencyManager.shared.currentNetworkType.rawValue else {
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
	}
	
	private func processAndShow(withWallet wallet: Wallet, operationRequest: OperationTezosRequest) {
		
		// Map all beacon objects to kuaki objects, and apply some logic to avoid having to deal with cumbersome beacon enum structure
		let convertedOps = BeaconService.process(operation: operationRequest, forWallet: wallet)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, withWallet: wallet) { [weak self] result in
			guard let estimatedOps = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.alert(errorWithMessage: "Processing Beacon request, unable to estimate fees")
				})
				return
			}
			
			self?.processTransactions(estimatedOperations: estimatedOps, operationRequest: operationRequest)
		}
	}
	
	private func processTransactions(estimatedOperations estimatedOps: [KukaiCoreSwift.Operation], operationRequest: OperationTezosRequest) {
		TransactionService.shared.currentTransactionType = .beaconOperation
		TransactionService.shared.beaconOperationData.estimatedOperations = estimatedOps
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
		})
	}
}
