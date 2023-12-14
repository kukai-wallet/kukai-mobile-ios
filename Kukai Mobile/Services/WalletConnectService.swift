//
//  WalletConnectService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/02/2023.
//

import Foundation
import KukaiCoreSwift
import Starscream
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
	func connectionStatusChanged(status: SocketConnectionStatus)
}

public struct WalletConnectGetAccountObj: Codable {
	let algo: String
	let address: String
	let pubkey: String
}

extension WebSocket: WebSocketConnecting {}

struct DefaultSocketFactory: WebSocketFactory {
	
	func create(with url: URL) -> WebSocketConnecting {
		let socket = WebSocket(url: url)
		let queue = DispatchQueue(label: "com.walletconnect.sdk.sockets", attributes: .concurrent)
		socket.callbackQueue = queue
		return socket
	}
}

public class WalletConnectService {
	
	private var bag = [AnyCancellable]()
	private var temporaryBag = [AnyCancellable]()
	
	public static let shared = WalletConnectService()
	public weak var delegate: WalletConnectServiceDelegate? = nil
	
	private static let projectId = "97f804b46f0db632c52af0556586a5f3"
	private static let metadata = AppMetadata(name: "Kukai iOS",
											  description: "Kukai iOS",
											  url: "https://wallet.kukai.app",
											  icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
											  redirect: AppMetadata.Redirect(native: "kukai://", universal: nil))
	
	@Published public var didCleanAfterDelete: Bool = false
	@Published public var requestDidComplete: Bool = false
	
	private init() {}
	
	public func setup() {
		
		// Objects and metadata
		Networking.configure(projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory())
		Pair.configure(metadata: WalletConnectService.metadata)
		
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
			DispatchQueue.main.async {
				self?.delegate?.connectionStatusChanged(status: status)
			}
		}.store(in: &bag)
		
		
		// Callbacks
		
		Sign.instance.sessionRequestPublisher
			.buffer(size: 10, prefetch: .byRequest, whenFull: .dropNewest)
			.flatMap(maxPublishers: .max(1)) { [weak self] sessionRequest in
				guard let self = self else {
					return Future<Bool, Never>() { promise in
						promise(.success(true))
					}
				}
				
				return self.processIncoming(request: sessionRequest.request)
			}
			.sink(receiveValue: { success in
				Logger.app.info("WC request completed with success: \(success)")
			})
			.store(in: &bag)
		
		Sign.instance.sessionProposalPublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] sessionProposal in
				Logger.app.info("WC sessionProposalPublisher")
				TransactionService.shared.walletConnectOperationData.proposal = sessionProposal.proposal
				self?.delegate?.pairRequested()
			}.store(in: &bag)
		
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { data in
				Logger.app.info("WC sessionSettlePublisher \(data.topic)")
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in 
				Logger.app.info("WC sessionDeletePublisher \(data.0)")
				Task { [weak self] in
					await WalletConnectService.cleanupSessionlessPairs()
					self?.didCleanAfterDelete = true
				}
			}.store(in: &bag)
	}
	
	
	
	// MARK: - Queue Management
	
	private func processIncoming(request: WalletConnectSign.Request) -> Future<Bool, Never> {
		Future() { [weak self] promise in
			Logger.app.info("Processing WC2 request method: \(request.method), for topic: \(request.topic), with id: \(request.id)")
			
			guard let self = self else {
				Logger.app.info("Unable to find self, cancelling")
				
				promise(.success(false))
				return
			}
			
			// Setup listener for completion status
			self.$requestDidComplete
				.dropFirst()
				.sink(receiveValue: { _ in
					promise(.success(true))
				})
				.store(in: &self.bag)
			
			
			// Process the request
			handleRequestLogic(request)
		}
	}
	
	private func handleRequestLogic(_ request: WalletConnectSign.Request) {
		TransactionService.shared.resetWalletConnectState()
		TransactionService.shared.walletConnectOperationData.request = request
		
		if request.method == "tezos_send" {
			processWalletConnectRequest()
			
		} else if request.method == "tezos_sign" {
			
			// Check for valid type
			if let params = try? request.params.get([String: String].self), let expression = params["payload"], expression.isMichelsonEncodedString(), expression.humanReadableStringFromMichelson() != "" {
				delegate?.signRequested()
			} else {
				Task {
					try? await WalletConnectService.reject(topic: request.topic, requestId: request.id)
					TransactionService.shared.resetWalletConnectState()
				}
				delegateErrorOnMain(message: "error-unsupported-sign".localized(), error: nil)
			}
			
		} else if request.method == "tezos_getAccounts" {
			delegate?.provideAccountList()
			
		} else {
			delegateErrorOnMain(message: "Unsupported WC method: \(request.method)", error: nil)
		}
	}
	
	private func delegateErrorOnMain(message: String, error: Error?) {
		DispatchQueue.main.async { [weak self] in
			self?.delegate?.error(message: message, error: error)
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
		Logger.app.info("WC pairing to \(uri.absoluteString)")
		Task {
			do {
				try await Pair.instance.pair(uri: uri)
				
			} catch {
				Logger.app.error("WC Pairing connect error: \(error)")
				delegateErrorOnMain(message: "Unable to connect to: \(uri.absoluteString), due to: \(error)", error: error)
			}
		}
	}
	
	@MainActor
	public func respondWithAccounts() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC Approve Session error: Unable to find request")
			delegateErrorOnMain(message: "Wallet connect: Unable to respond to request for list of wallets", error: nil)
			return
		}
		
		Logger.app.info("WC Approve Request: \(request.id)")
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
				Logger.app.error("WC Approve Session error: \(error)")
				delegateErrorOnMain(message: "Wallet connect: error returning list of accounts: \(error)", error: error)
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
	public static func reject(proposalId: String, reason: RejectionReason) throws {
		Logger.app.info("WC Reject Pairing \(proposalId)")
		Task {
			try await Sign.instance.reject(proposalId: proposalId, reason: reason)
			TransactionService.shared.resetWalletConnectState()
		}
	}
	
	@MainActor
	public static func reject(topic: String, requestId: RPCID) throws {
		Logger.app.info("WC Reject Request topic: \(topic), id: \(requestId.description)")
		Task {
			try await Sign.instance.respond(topic: topic, requestId: requestId, response: .error(.init(code: 0, message: "")))
			TransactionService.shared.resetWalletConnectState()
			WalletConnectService.shared.requestDidComplete = true
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
		guard let wcRequest = TransactionService.shared.walletConnectOperationData.request else {
			self.delegateErrorOnMain(message: "Unable to process wallet connect request", error: nil)
			return
		}
		
		DependencyManager.shared.tezosNodeClient.getNetworkInformation { _, error in
			if let err = error {
				self.delegateErrorOnMain(message: "Unable to fetch info from the Tezos node, please try again", error: err)
				return
			}
			
			
			guard let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
				  (wcRequest.chainId.absoluteString == "tezos:\(tezosChainName)" || (wcRequest.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
			else {
				let onDevice = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
				self.delegateErrorOnMain(message: "Request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match", error: nil)
				return
			}
			
			guard let params = try? wcRequest.params.get(WalletConnectRequestParams.self), let wallet = WalletCacheService().fetchWallet(forAddress: params.account) else {
				self.delegateErrorOnMain(message: "Unable to parse response or locate wallet", error: nil)
				return
			}
			
			TransactionService.shared.walletConnectOperationData.requestParams = params
			self.delegate?.processingIncomingOperations()
			
			// Map all wallet connect objects to kuaki objects
			let convertedOps = params.kukaiOperations()
			
			DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
				guard let estimationResult = try? result.get() else {
					self?.delegateErrorOnMain(message: "Unable to estimate fees", error: result.getFailure())
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
			
		}/* else if let transactionOperation = OperationFactory.Extractor.isTezTransfer(operations: operations) as? OperationTransaction {
			
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
			
		}*/ else if let result = OperationFactory.Extractor.faTokenDetailsFrom(operations: operationsObj.selectedOperationsAndFees()),
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
			var firstTransaction: OperationTransaction? = nil
			let totalAmount = operations.compactMap({ ($0 as? OperationTransaction)?.amount }).compactMap({ XTZAmount(fromRpcAmount: $0) }).reduce(XTZAmount.zero(), +)
			
			if let transactionOperation = OperationFactory.Extractor.isTezTransfer(operations: operations) as? OperationTransaction {
				firstTransaction = transactionOperation
			} else {
				firstTransaction = operations.first(where: { ($0 as? OperationTransaction)?.destination != nil }) as? OperationTransaction
			}
			
			
			
			DependencyManager.shared.tezosNodeClient.getBalance(forAddress: forWallet.address) { [weak self] res in
				let accountBalance = (try? res.get()) ?? totalAmount
				let selectedToken = Token.xtz(withAmount: accountBalance)
				
				TransactionService.shared.walletConnectOperationData.currentTransactionType = .send
				TransactionService.shared.walletConnectOperationData.sendData.chosenToken = selectedToken
				TransactionService.shared.walletConnectOperationData.sendData.chosenAmount = totalAmount
				TransactionService.shared.walletConnectOperationData.sendData.destination = firstTransaction?.destination ?? ""
				self?.mainThreadProcessedOperations(ofType: .sendToken)
			}
		}
	}
	
	private func mainThreadProcessedOperations(ofType type: WalletConnectOperationType) {
		DispatchQueue.main.async {
			self.delegate?.processedOperations(ofType: type)
		}
	}
}
