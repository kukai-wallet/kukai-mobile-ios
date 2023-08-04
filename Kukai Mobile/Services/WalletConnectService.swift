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
	private var temporaryBag = [AnyCancellable]()
	
	public static let shared = WalletConnectService()
	public weak var delegate: WalletConnectServiceDelegate? = nil
	public var uriToOpenOnAppReturn: WalletConnectURI? = nil
	
	private static let projectId = "97f804b46f0db632c52af0556586a5f3"
	private static let metadata = AppMetadata(name: "Kukai iOS",
											  description: "Kukai iOS",
											  url: "https://wallet.kukai.app",
											  icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
											  redirect: AppMetadata.Redirect(native: "kukai://app", universal: nil))
	
	@Published public var didCleanAfterDelete: Bool = false
	
	private init() {}
	
	public func setup() {
		
		// Objects and metadata
		Networking.configure(projectId: WalletConnectService.projectId, socketFactory: NativeSocketFactory(), socketConnectionType: .manual)
		Pair.configure(metadata: WalletConnectService.metadata)
		
		try? Networking.instance.connect()
		
		// Callbacks
		Sign.instance.sessionRequestPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionRequest in
				os_log("WC sessionRequestPublisher", log: .default, type: .info)
				
				TransactionService.shared.resetWalletConnectState()
				TransactionService.shared.walletConnectOperationData.request = sessionRequest.request
				
				if sessionRequest.request.method == "tezos_send" {
					self?.processWalletConnectRequest()
					
				} else if sessionRequest.request.method == "tezos_sign" {
					self?.delegate?.signRequested()
					
				} else if sessionRequest.request.method == "tezos_getAccounts" {
					self?.delegate?.provideAccountList()
					
				} else {
					self?.delegate?.error(message: "Unsupported WC method: \(sessionRequest.request.method)", error: nil)
				}
				
			}.store(in: &bag)
		
		Sign.instance.sessionProposalPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionProposal in
				os_log("WC sessionProposalPublisher %@", log: .default, type: .info)
				TransactionService.shared.walletConnectOperationData.proposal = sessionProposal.proposal
				self?.delegate?.pairRequested()
			}.store(in: &bag)
		
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { /*[weak self]*/ data in
				os_log("WC sessionSettlePublisher %@", log: .default, type: .info, data.topic)
				//self?.viewModel.refresh(animate: true)
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in 
				os_log("WC sessionDeletePublisher %@", log: .default, type: .info, data.0)
				Task { [weak self] in
					await WalletConnectService.cleanupSessionlessPairs()
					self?.didCleanAfterDelete = true
				}
			}.store(in: &bag)
	}
	
	public func reconnect(completion: @escaping ((Error?) -> Void)) {
		bag.forEach({ $0.cancel() })
		bag = []
		
		Networking.instance.socketConnectionStatusPublisher.dropFirst().sink { [weak self] value in
			completion(nil)
			
			self?.temporaryBag.forEach({ $0.cancel() })
			
		}.store(in: &temporaryBag)
		
		do {
			try Networking.instance.disconnect(closeCode: .normalClosure)
			self.setup()
			
		} catch (let error) {
			completion(error)
		}
	}
	
	public func disconnectForAppClose() {
		if delegate != nil {
			try? Networking.instance.disconnect(closeCode: .normalClosure)
		}
	}
	
	public func connectOnAppOpen() {
		if delegate != nil {
			self.reconnect { _ in
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					
					if let uri = WalletConnectService.shared.uriToOpenOnAppReturn {
						WalletConnectService.shared.pairClient(uri: uri)
					}
				}
			}
		}
	}
	
	
	
	// MARK: - Namespaces
	
	public static func createNamespace(forProposal proposal: Session.Proposal, address: String, currentNetworkType: TezosNodeClientConfig.NetworkType) -> [String: SessionNamespace]? {
		
		var sessionNamespaces = [String: SessionNamespace]()
		
		let supportedMethods = ["tezos_send", "tezos_sign", "tezos_getAccounts"]
		let supportedEvents: [String] = []
		
		let requiredMethods = proposal.requiredNamespaces["tezos"]?.methods.filter({ supportedMethods.contains([$0]) })
		let optionalMethods = proposal.optionalNamespaces?["tezos"]?.methods.filter({ supportedMethods.contains([$0]) }) ?? []
		let approvedMethods = requiredMethods?.union( optionalMethods )
		
		let requiredEvents = proposal.requiredNamespaces["tezos"]?.events.filter({ supportedEvents.contains([$0]) })
		let optionalEvents = proposal.optionalNamespaces?["tezos"]?.methods.filter({ supportedEvents.contains([$0]) }) ?? []
		let approvedEvents = requiredEvents?.union( optionalEvents )
		
		
		let network = currentNetworkType == .mainnet ? "mainnet" : "ghostnet"
		if let wcAccount = Account("tezos:\(network):\(address)") {
			let accounts: Set<WalletConnectSign.Account> = Set([wcAccount])
			let sessionNamespace = SessionNamespace(accounts: accounts, methods: approvedMethods ?? [], events: approvedEvents ?? [])
			sessionNamespaces["tezos"] = sessionNamespace
			
			return sessionNamespaces
			
		} else {
			return nil
		}
	}
	
	public static func updateNamespaces(forPairing pairing: Pairing, toAddress: String/*, andNetwork newNetwork: TezosNodeClientConfig.NetworkType*/) -> [String: SessionNamespace]? {
		let session = Sign.instance.getSessions().first(where: { $0.pairingTopic == pairing.topic })
		var tezosNamespace = session?.namespaces["tezos"]
		
		let previousNetwork = tezosNamespace?.accounts.first?.blockchain.reference ?? (DependencyManager.shared.currentNetworkType == .mainnet ? "mainnet" : "ghostnet")
		if let newAccount = Account("tezos:\(previousNetwork):\(toAddress)") {
			tezosNamespace?.accounts = Set([newAccount])
		}
		
		if let namespace = tezosNamespace {
			return ["tezos": namespace]
		}
		
		return nil
	}
	
	
	
	// MARK: - Pairing
	
	@MainActor
	public func pairClient(uri: WalletConnectURI) {
		os_log("WC pairing to %@", log: .default, type: .info, uri.absoluteString)
		Task {
			do {
				try await Pair.instance.pair(uri: uri)
				uriToOpenOnAppReturn = nil
				
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
	
	@MainActor
	public static func cleanupSessionlessPairs() async {
		var pairsToClean: [Pairing] = []
		Pair.instance.getPairings().forEach({ pair in
			let sessions = Sign.instance.getSessions().filter({ $0.pairingTopic == pair.topic })
			if sessions.count == 0 {
				pairsToClean.append(pair)
			}
		})
		
		await pairsToClean.asyncForEach({ pair in
			try? await Pair.instance.disconnect(topic: pair.topic)
		})
	}
	
	
	@MainActor
	public static func cleanupDanglingPairings() async {
		var pairsToClean: [Pairing] = []
		Pair.instance.getPairings().forEach({ pair in
			if pair.peer == nil {
				pairsToClean.append(pair)
			}
		})
		
		await pairsToClean.asyncForEach({ pair in
			try? await Pair.instance.disconnect(topic: pair.topic)
			
			await Sign.instance.getSessions().filter({ $0.pairingTopic == pair.topic }).asyncForEach({ session in
				try? await Sign.instance.disconnect(topic: session.topic)
			})
		})
	}
	
	@MainActor
	public static func reject(proposalId: String, reason: RejectionReason) throws {
		os_log("WC Reject Pairing %@", log: .default, type: .info, proposalId)
		Task {
			try await Sign.instance.reject(proposalId: proposalId, reason: reason)
			await WalletConnectService.cleanupDanglingPairings()
			TransactionService.shared.resetWalletConnectState()
		}
	}
	
	@MainActor
	public static func reject(topic: String, requestId: RPCID) throws {
		os_log("WC Reject Request topic: %@, id: %@", log: .default, type: .info, topic, requestId.description)
		Task {
			try await Sign.instance.respond(topic: topic, requestId: requestId, response: .error(.init(code: 0, message: "")))
			TransactionService.shared.resetWalletConnectState()
		}
	}
	
	
	// MARK: - Operations
	
	public static func accountFromRequest(_ request: WalletConnectSign.Request?) -> String? {
		guard let params = try? request?.params.get(WalletConnectRequestParams.self) else {
			return nil
		}
		
		return params.account
	}
	
	private func processWalletConnectRequest() {
		DependencyManager.shared.tezosNodeClient.getNetworkInformation { _, error in
			if let err = error {
				self.delegate?.error(message: "Unable to fetch info from the Tezos node, please try again", error: err)
				return
			}
			
			
			guard let wcRequest = TransactionService.shared.walletConnectOperationData.request,
				  let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
				  (wcRequest.chainId.absoluteString == "tezos:\(tezosChainName)" || (wcRequest.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
			else {
				let onDevice = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
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
				guard let estimationResult = try? result.get() else {
					self?.delegate?.error(message: "Processing WalletConnect request, unable to estimate fees", error: result.getFailure())
					return
				}
				
				self?.processTransactions(estimationResult: estimationResult, forWallet: wallet)
			}
		}
	}
	
	private func processTransactions(estimationResult: FeeEstimatorService.EstimationResult, forWallet: Wallet) {
		let operationsObj = TransactionService.OperationsAndFeesData(estimatedOperations: estimationResult.operations)
		let operations = operationsObj.selectedOperationsAndFees()
		
		TransactionService.shared.currentRemoteOperationsAndFeesData = operationsObj
		TransactionService.shared.currentRemoteForgedString = estimationResult.forgedString
		
		if let contractDetails = OperationFactory.Extractor.isContractCall(operations: operations) {
			let totalXTZ = OperationFactory.Extractor.totalXTZAmountForContractCall(operations: operations)
			TransactionService.shared.walletConnectOperationData.currentTransactionType = .contractCall
			TransactionService.shared.walletConnectOperationData.contractCallData = TransactionService.ContractCallData(chosenToken: Token.xtz(), chosenAmount: totalXTZ, contractAddress: contractDetails.address, operationCount: operations.count, mainEntrypoint: contractDetails.entrypoint)
			mainThreadProcessedOperations(ofType: .contractCall)
			
		} else if OperationFactory.Extractor.isTezTransfer(operations: operations), let transactionOperation = operations.first as? OperationTransaction {
			
			DependencyManager.shared.tezosNodeClient.getBalance(forAddress: forWallet.address) { [weak self] res in
				let xtzAmount = XTZAmount(fromRpcAmount: transactionOperation.amount) ?? .zero()
				let accountBalance = (try? res.get()) ?? xtzAmount
				let selectedToken = Token.xtz(withAmount: accountBalance)
				
				TransactionService.shared.walletConnectOperationData.currentTransactionType = .send
				TransactionService.shared.walletConnectOperationData.sendData.chosenToken = selectedToken
				TransactionService.shared.walletConnectOperationData.sendData.chosenAmount = xtzAmount
				TransactionService.shared.walletConnectOperationData.sendData.destination = transactionOperation.destination
				self?.mainThreadProcessedOperations(ofType: .sendToken)
			}
			
		} else if let result = OperationFactory.Extractor.faTokenDetailsFrom(operations: operationsObj.selectedOperationsAndFees()),
				  let token = DependencyManager.shared.balanceService.token(forAddress: result.tokenContract, andTokenId: result.tokenId) {
			
			TransactionService.shared.walletConnectOperationData.currentTransactionType = .send
			TransactionService.shared.walletConnectOperationData.sendData.destination = result.destination
			TransactionService.shared.walletConnectOperationData.sendData.chosenAmount = TokenAmount(fromRpcAmount: result.rpcAmount, decimalPlaces: token.token.decimalPlaces)
			
			if token.isNFT, let nft = (token.token.nfts ?? []).first(where: { $0.tokenId == result.tokenId }) {
				TransactionService.shared.walletConnectOperationData.sendData.chosenNFT = nft
				mainThreadProcessedOperations(ofType: .sendNft)
				
			} else {
				TransactionService.shared.walletConnectOperationData.sendData.chosenToken = token.token
				mainThreadProcessedOperations(ofType: .sendToken)
			}
			
		} else {
			TransactionService.shared.walletConnectOperationData.currentTransactionType = .contractCall
			mainThreadProcessedOperations(ofType: .contractCall)
		}
	}
	
	private func mainThreadProcessedOperations(ofType type: WalletConnectOperationType) {
		DispatchQueue.main.async {
			self.delegate?.processedOperations(ofType: type)
		}
	}
}
