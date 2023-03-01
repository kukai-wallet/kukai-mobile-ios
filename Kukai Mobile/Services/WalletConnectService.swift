//
//  WalletConnectService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/02/2023.
//

import Foundation
import KukaiCoreSwift
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectSign
import Combine
import OSLog

public enum WalletConnectOperationType {
	case sendToken
	case sendNft
	case contractCall
}

public protocol WalletConnectServiceDelegate: AnyObject {
	func pairRequested()
	func signRequested()
	func processingIncomingOperations()
	func processedOperations(ofType: WalletConnectOperationType)
	func error(message: String?, error: Error?)
}

public class WalletConnectService {
	
	private var bag = [AnyCancellable]()
	
	public static let shared = WalletConnectService()
	public weak var delegate: WalletConnectServiceDelegate? = nil
	
	private init() {}
	
	public func setup() {
		
		// Objects and metadata
		Networking.configure(projectId: "97f804b46f0db632c52af0556586a5f3", socketFactory: NativeSocketFactory())
		let metadata = AppMetadata(name: "Kukai iOS",
								   description: "Kukai iOS",
								   url: "https://wallet.kukai.app",
								   icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
								   redirect: AppMetadata.Redirect(native: "kukai://app", universal: nil))
		Pair.configure(metadata: metadata)
		
		
		
		// Callbacks
		Sign.instance.sessionRequestPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionRequest in
				os_log("WC sessionRequestPublisher", log: .default, type: .info)
				
				TransactionService.shared.walletConnectOperationData.request = sessionRequest
				
				if sessionRequest.method == "tezos_send" {
					self?.processWalletConnectRequest()
					
				} else if sessionRequest.method == "tezos_sign" {
					self?.delegate?.signRequested()
					
				} else if sessionRequest.method == "tezos_getAccounts" {
					self?.delegate?.error(message: "Unsupported WC method: \(sessionRequest.method)", error: nil)
					
				} else {
					self?.delegate?.error(message: "Unsupported WC method: \(sessionRequest.method)", error: nil)
				}
				
			}.store(in: &bag)
		
		Sign.instance.sessionProposalPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionProposal in
				os_log("WC sessionProposalPublisher %@", log: .default, type: .info)
				TransactionService.shared.walletConnectOperationData.proposal = sessionProposal
				self?.delegate?.pairRequested()
			}.store(in: &bag)
		
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { /*[weak self]*/ _ in
				os_log("WC sessionSettlePublisher %@", log: .default, type: .info)
				//self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { /*[weak self]*/ _ in
				os_log("WC sessionDeletePublisher %@", log: .default, type: .info)
				//self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
	}
	
	
	
	// MARK: - Pairing
	
	@MainActor
	public func pairClient(uri: WalletConnectURI) {
		os_log("WC pairing to %@", log: .default, type: .info, uri.absoluteString)
		Task {
			do {
				try await Pair.instance.pair(uri: uri)
			} catch {
				os_log("WC Pairing connect error: %@", log: .default, type: .error, "\(error)")
				self.delegate?.error(message: "Unable to connect to: \(uri.absoluteString), due to: \(error)", error: error)
			}
		}
	}
	
	
	
	// MARK: - Operations
	
	private func processWalletConnectRequest() {
		guard let wcRequest = TransactionService.shared.walletConnectOperationData.request,
			  let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
			  (wcRequest.chainId.absoluteString == "tezos:\(tezosChainName)" || (wcRequest.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
		else {
			let onDevice = "tezos:\(DependencyManager.shared.tezosNodeClient.networkVersion?.chainName() ?? "")"
			self.delegate?.error(message: "Processing WalletConnect request, request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match", error: nil)
			return
		}
		
		guard let params = try? wcRequest.params.get(WalletConnectRequestParams.self), let wallet = WalletCacheService().fetchWallet(forAddress: params.account) else {
			self.delegate?.error(message: "Processing WalletConnect request, unable to parse response or locate wallet", error: nil)
			return
		}
		
		TransactionService.shared.walletConnectOperationData.requestParams = params
		self.delegate?.processingIncomingOperations()
		
		// Map all beacon objects to kuaki objects
		let convertedOps = params.kukaiOperations()
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
			guard let estimatedOps = try? result.get() else {
				self?.delegate?.error(message: "Processing WalletConnect request, unable to estimate fees", error: nil)
				return
			}
			
			self?.processTransactions(estimatedOperations: estimatedOps)
		}
	}
	
	private func processTransactions(estimatedOperations estimatedOps: [KukaiCoreSwift.Operation]) {
		TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps)
		
		if estimatedOps.first is KukaiCoreSwift.OperationTransaction, let transactionOperation = estimatedOps.first as? KukaiCoreSwift.OperationTransaction {
			
			if transactionOperation.parameters == nil {
				let xtzAmount = XTZAmount(fromRpcAmount: transactionOperation.amount) ?? .zero()
				let amount = Token.xtz(withAmount: xtzAmount)
				
				TransactionService.shared.currentTransactionType = .send
				TransactionService.shared.sendData.chosenToken = amount
				TransactionService.shared.sendData.chosenAmount = xtzAmount
				TransactionService.shared.sendData.destination = transactionOperation.destination
				
			} else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint == "transfer", let token = DependencyManager.shared.balanceService.token(forAddress: transactionOperation.destination) {
				if token.isNFT {
					// TransactionService.shared.sendData.chosenNFT = token.token.n
				} else {
					TransactionService.shared.sendData.chosenToken = token.token
				}
				TransactionService.shared.currentTransactionType = .send
				//TransactionService.shared.sendData.chosenAmount = xtzAmount
				TransactionService.shared.sendData.destination = transactionOperation.destination
				
			}/* else if let entrypoint = transactionOperation.parameters?["entrypoint"] as? String, entrypoint != "transfer" {
			  TransactionService.shared.walletConnectOperationData.operationType = .callSmartContract
			  TransactionService.shared.walletConnectOperationData.entrypointToCall = entrypoint
			  
			  } else {
			  TransactionService.shared.walletConnectOperationData.operationType = .unknown
			  }*/
			
			// TODO: need NFT + contract call processing here
			
			
		} else {
			TransactionService.shared.currentTransactionType = .none
		}
		
		if TransactionService.shared.currentTransactionType == .send, TransactionService.shared.sendData.chosenToken == nil {
			self.delegate?.processedOperations(ofType: .sendNft)
			
		} else {
			self.delegate?.processedOperations(ofType: .sendToken)
		}
	}
}
