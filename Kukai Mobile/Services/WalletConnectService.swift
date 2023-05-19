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
	func provideAccountList()
	func error(message: String?, error: Error?)
}

public struct WalletConnectGetAccountObj: Codable {
	let algo: String
	let address: String
	let pubkey: String
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
				
				TransactionService.shared.resetState()
				TransactionService.shared.walletConnectOperationData.request = sessionRequest
				
				if sessionRequest.method == "tezos_send" {
					self?.processWalletConnectRequest()
					
				} else if sessionRequest.method == "tezos_sign" {
					self?.delegate?.signRequested()
					
				} else if sessionRequest.method == "tezos_getAccounts" {
					self?.delegate?.provideAccountList()
					
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
	
	@MainActor
	public func respondWithAccounts() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Approve Session error: Unable to find request", log: .default, type: .error)
			self.delegate?.error(message: "Wallet connect: Unable to respond to request for list of wallets", error: nil)
			return
		}
		
		os_log("WC Approve Request: %@", log: .default, type: .info, "\(request.id)")
		Task {
			do {
				/*
				// list all accounts
				var accounts: [WalletConnectGetAccountObj] = []
				for wallet in DependencyManager.shared.walletList.allMetadata() {
					
					let prefix = wallet.address.prefix(3).lowercased()
					var algo = ""
					if prefix == "tz1" {
						algo = "ed25519"
					} else if prefix == "tz2" {
						algo = "secp256k1"
					} else {
						algo = "unknown"
					}
					
					accounts.append(WalletConnectGetAccountObj(algo: algo, address: wallet.address, pubkey: wallet.bas58EncodedPublicKey))
				}
				
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(accounts)))
				*/
				
				// List current account
				let currentAccount = DependencyManager.shared.selectedWalletMetadata
				let prefix = currentAccount?.address.prefix(3).lowercased() ?? ""
				var algo = ""
				if prefix == "tz1" {
					algo = "ed25519"
				} else if prefix == "tz2" {
					algo = "secp256k1"
				} else {
					algo = "unknown"
				}
				
				let obj = WalletConnectGetAccountObj(algo: algo, address: currentAccount?.address ?? "", pubkey: currentAccount?.bas58EncodedPublicKey ?? "")
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable([obj])))
				
			} catch {
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.delegate?.error(message: "Wallet connect: error returning list of accounts: \(error)", error: error)
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
		
		// Map all wallet connect objects to kuaki objects
		let convertedOps = params.kukaiOperations()
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
			guard let estimatedOps = try? result.get() else {
				self?.delegate?.error(message: "Processing WalletConnect request, unable to estimate fees", error: nil)
				return
			}
			
			self?.processTransactions(estimatedOperations: estimatedOps, forWallet: wallet)
		}
	}
	
	private func processTransactions(estimatedOperations estimatedOps: [KukaiCoreSwift.Operation], forWallet: Wallet) {
		TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps)
		let operations = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps).selectedOperationsAndFees()
		
		if let contractDetails = OperationFactory.Extractor.isContractCall(operations: operations) {
			let totalXTZ = OperationFactory.Extractor.totalXTZAmountForContractCall(operations: operations)
			TransactionService.shared.currentTransactionType = .contractCall
			TransactionService.shared.contractCallData = TransactionService.ContractCallData(chosenToken: Token.xtz(), chosenAmount: totalXTZ, contractAddress: contractDetails.address, operationCount: operations.count, mainEntrypoint: contractDetails.entrypoint)
			mainThreadProcessedOperations(ofType: .contractCall)
			
		} else if OperationFactory.Extractor.isTezTransfer(operations: operations), let transactionOperation = operations.first as? OperationTransaction {
			
			DependencyManager.shared.tezosNodeClient.getBalance(forAddress: forWallet.address) { [weak self] res in
				let xtzAmount = XTZAmount(fromRpcAmount: transactionOperation.amount) ?? .zero()
				let accountBalance = (try? res.get()) ?? xtzAmount
				let selectedToken = Token.xtz(withAmount: accountBalance)
				
				TransactionService.shared.currentTransactionType = .send
				TransactionService.shared.sendData.chosenToken = selectedToken
				TransactionService.shared.sendData.chosenAmount = xtzAmount
				TransactionService.shared.sendData.destination = transactionOperation.destination
				self?.mainThreadProcessedOperations(ofType: .sendToken)
			}
			
		} else if let result = OperationFactory.Extractor.faTokenDetailsFrom(operations: TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOps).selectedOperationsAndFees()),
				  let token = DependencyManager.shared.balanceService.token(forAddress: result.tokenContract, andTokenId: result.tokenId) {
			
			TransactionService.shared.currentTransactionType = .send
			TransactionService.shared.sendData.destination = result.destination
			TransactionService.shared.sendData.chosenAmount = TokenAmount(fromRpcAmount: result.rpcAmount, decimalPlaces: token.token.decimalPlaces)
			
			if token.isNFT, let nft = (token.token.nfts ?? []).first(where: { $0.tokenId == result.tokenId }) {
				TransactionService.shared.sendData.chosenNFT = nft
				
			} else {
				TransactionService.shared.sendData.chosenToken = token.token
			}
			
			mainThreadProcessedOperations(ofType: .sendToken)
			
		} else {
			TransactionService.shared.currentTransactionType = .contractCall
			mainThreadProcessedOperations(ofType: .contractCall)
		}
	}
	
	private func mainThreadProcessedOperations(ofType type: WalletConnectOperationType) {
		DispatchQueue.main.async {
			self.delegate?.processedOperations(ofType: type)
		}
	}
}
