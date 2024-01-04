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

struct RequestOperation: Codable {
	let account: String
}

public class WalletConnectService {
	
	public static let shared = WalletConnectService()
	public var deepLinkPairingToConnect: WalletConnectURI? = nil
	public var hasBeenSetup = false
	public weak var delegate: WalletConnectServiceDelegate? = nil
	
	private var bag = [AnyCancellable]()
	private static let projectId = "97f804b46f0db632c52af0556586a5f3"
	private static let metadata = AppMetadata(name: "Kukai iOS",
											  description: "Kukai iOS",
											  url: "https://wallet.kukai.app",
											  icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
											  redirect: AppMetadata.Redirect(native: "kukai://", universal: nil))
	
	@Published public var requestDidComplete: Bool = false
	@Published public var pairsAndSessionsUpdated: Bool = false
	
	/// This publisher serves as a means to combine WalletConnect's`sessionProposalPublisherSubject` and `sessionRequestPublisherSubject`,
	/// the subjects action output will either be a `WalletConnectSign.Session.Proposal` or a `WalletConnectSign.Request`.
	/// This will enable the ability to apply a buffer to all events that a user must interact with, so they can be presented/handled one at a time without the need for multiple async delays, guessing when everything is finished, and simplifying the code
	private let sessionActionRequiredPublisherSubject = PassthroughSubject<(action: Any, context: VerifyContext?), Never>()
	
	private init() {}
	
	public func setup() {
		
		// Objects and metadata
		Networking.configure(groupIdentifier: "group.app.kukai.mobile", projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory())
		Pair.configure(metadata: WalletConnectService.metadata)
		
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
			DispatchQueue.main.async {
				self?.delegate?.connectionStatusChanged(status: status)
			}
		}.store(in: &bag)
		
		
		// Callbacks
		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { data in
				Logger.app.info("WC sessionSettlePublisher \(data.topic)")
			}.store(in: &bag)
		
		Sign.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in 
				Logger.app.info("WC sessionDeletePublisher \(data.0)")
				self?.pairsAndSessionsUpdated = true
			}.store(in: &bag)
		
		(Pair.instance as? PairingClient)?.pairingDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { data in
				Logger.app.info("WC pairingDeletePublisher \(data.code), \(data.message)")
			}.store(in: &bag)
		
		
		// Setup central buffered publisher for items that require user input and can't be handled more than 1 at a time
		// Each item will be wrapped in a future, that is listening to a published var waiting for a user action to mark it as handled (either success or reject)
		sessionActionRequiredPublisherSubject
			.receive(on: DispatchQueue.main)
			.buffer(size: 10, prefetch: .byRequest, whenFull: .dropNewest)
			.flatMap(maxPublishers: .max(1)) { [weak self] userActionItem in
				
				guard let self = self else {
					Logger.app.error("WC sessionActionRequiredPublisherSubject can't find self, skipping action")
					return Future<Bool, Never>() { $0(.success(false)) }
				}
				
				if let proposal = userActionItem.action as? Session.Proposal {
					Logger.app.error("WC sessionActionRequiredPublisherSubject received a proposal")
					return self.wrapProposalAsFuture(proposal: proposal)
					
				} else if let request = userActionItem.action as? Request {
					Logger.app.error("WC sessionActionRequiredPublisherSubject received a request")
					return self.wrapRequestAsFuture(request: request)
					
				} else {
					Logger.app.error("WC sessionActionRequiredPublisherSubject received an unknown type, skipping")
					return Future<Bool, Never>() { $0(.success(false)) }
				}
			}
			.sink(receiveValue: { success in
				Logger.app.info("WC request completed with success: \(success)")
			})
			.store(in: &bag)
		
		
		// Pass WC2 objects to central buffered publisher, as they require identical UI/UX management (displying bottom sheet, requesting user interaction)
		Sign.instance.sessionProposalPublisher
			.sink { [weak self] incomingProposalObj in
				Logger.app.info("WC sessionProposalPublisher")
				self?.sessionActionRequiredPublisherSubject.send((action: incomingProposalObj.proposal, context: incomingProposalObj.context))
			}.store(in: &bag)
		
		Sign.instance.sessionRequestPublisher
			.sink { [weak self] incomingProposalObj in
				Logger.app.info("WC sessionRequestPublisher")
				self?.sessionActionRequiredPublisherSubject.send((action: incomingProposalObj.request, context: incomingProposalObj.context))
				
			}.store(in: &bag)
		
		
		hasBeenSetup = true
		
		if let uri = deepLinkPairingToConnect {
			Task {
				await pairClient(uri: uri)
				deepLinkPairingToConnect = nil
			}
		}
	}
	
	
	
	// MARK: - Queue Management
	
	private func wrapProposalAsFuture(proposal: Session.Proposal) -> Future<Bool, Never> {
		return Future<Bool, Never>() { [weak self] promise in
			
			guard let self = self else {
				Logger.app.error("WC wrapProposalAsFuture failed to find self, returning false")
				promise(.success(false))
				return
			}
			
			
			// Record proposal in shared state so it can be accessed by various methods and screens
			Logger.app.info("Processing WC2 proposal: \(proposal.id)")
			TransactionService.shared.walletConnectOperationData.proposal = proposal
			
			
			// Check if the proposal is for the network the app is currently on
			self.checkValidNetwork(forProposal: proposal) { [weak self] isValid in
				guard isValid else {
					Logger.app.info("Request is for the wrong network, rejecting")
					promise(.success(false))
					return
				}
				
				self?.delegate?.pairRequested()
			}
			
			
			// Setup listener for user action confirming the proposal has been handled or rejected
			self.$requestDidComplete
				.dropFirst()
				.sink(receiveValue: { value in
					promise(.success(value))
				})
				.store(in: &self.bag)
		}
	}
	
	private func wrapRequestAsFuture(request: Request) -> Future<Bool, Never> {
		return Future<Bool, Never>() { [weak self] promise in
			
			guard let self = self else {
				Logger.app.error("WC wrapRequestAsFuture failed to find self, returning false")
				promise(.success(false))
				return
			}
			
			
			// Record request in shared state so it can be accessed by various methods and screens
			Logger.app.info("Processing WC2 request method: \(request.method), for topic: \(request.topic), with id: \(request.id)")
			TransactionService.shared.walletConnectOperationData.request = request
			
			
			// Check if the request is for the correct network, and requesting for the correct account
			// TODO: The tezos provider should be performing the account check at a minimum, when the provider is replaced, remove this check
			self.checkValidNetworkAndAccount(forRequest: request) { [weak self] isValid in
				
				guard isValid else {
					Logger.app.info("Request is for the wrong network, rejecting")
					promise(.success(false))
					return
				}
				
				guard let self = self else {
					Logger.app.info("Unable to find self, cancelling")
					promise(.success(false))
					return
				}
				
				// Setup listener for completion status
				self.$requestDidComplete
					.dropFirst()
					.sink(receiveValue: { value in
						promise(.success(value))
					})
					.store(in: &self.bag)
				
				
				// Process the request
				self.handleRequestLogic(request)
			}
		}
	}
	
	/// Check if the proposal network matches the current one the app is pointing too. Return false in completion block if its not, and fire off a message to delegate error hanlder if so. Calling code only needs to check for if true
	private func checkValidNetwork(forProposal proposal: WalletConnectSign.Session.Proposal, completion: @escaping ((Bool) -> Void)) {
		DependencyManager.shared.tezosNodeClient.getNetworkInformation { [weak self] _, error in
			if let err = error {
				WalletConnectService.rejectCurrentProposal(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "Unable to fetch info from the Tezos node, please try again", error: err)
				completion(false)
				return
			}
			
			guard let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
				  let namespace = proposal.requiredNamespaces["tezos"],
				  let chain = namespace.chains?.first,
				  (chain.absoluteString == "tezos:\(tezosChainName)" || (chain.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
			else {
				let onDevice = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
				WalletConnectService.rejectCurrentProposal(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "Request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match", error: nil)
				completion(false)
				return
			}
			
			completion(true)
		}
	}
	
	/// Check if the request network matches the current one the app is pointing too. Return false in completion block if its not, and fire off a message to delegate error hanlder if so. Calling code only needs to check for if true
	private func checkValidNetworkAndAccount(forRequest request: WalletConnectSign.Request, completion: @escaping ((Bool) -> Void)) {
		DependencyManager.shared.tezosNodeClient.getNetworkInformation { [weak self] _, error in
			if let err = error {
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "Unable to fetch info from the Tezos node, please try again", error: err)
				completion(false)
				return
			}
			
			
			// Check the chain is the current chain
			guard let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
				  (request.chainId.absoluteString == "tezos:\(tezosChainName)" || (request.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
			else {
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				let onDevice = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
				self?.delegateErrorOnMain(message: "Request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match", error: nil)
				completion(false)
				return
			}
			
			
			// Check the requested account and method were previously allowed
			let session = Sign.instance.getSessions().filter({ $0.topic == request.topic }).first
			let allowedAccounts = session?.namespaces["tezos"]?.accounts.map({ $0.absoluteString }) ?? []
			let allowedMethods = session?.namespaces["tezos"]?.methods ?? []
			
			let requestedAccount = (try? request.params.get(RequestOperation.self).account) ?? ""
			let normalisedChainName = (tezosChainName == "ithacanet") ? "ghostnet" : tezosChainName
			let fullRequestedAccount = "tezos:\(normalisedChainName):\(requestedAccount)"
			let requestedMethod = request.method
			
			guard requestedMethod == "tezos_getAccounts" || allowedAccounts.contains(fullRequestedAccount) else {
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "The requested account \(requestedAccount.truncateTezosAddress()), was not authorised to perform this action. Please ensure you have paired this account with the remote application.", error: nil)
				completion(false)
				return
			}
			
			guard allowedMethods.contains(requestedMethod) else {
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "The requested method \(requestedMethod), was not authorised for this account. Please ensure you have paired this account with the remote application.", error: nil)
				completion(false)
				return
			}
			
			completion(true)
		}
	}
	
	private func handleRequestLogic(_ request: WalletConnectSign.Request) {
		
		if request.method == "tezos_send" {
			processWalletConnectRequest()
			
		} else if request.method == "tezos_sign" {
			
			// Check for valid type
			if let params = try? request.params.get([String: String].self), let expression = params["payload"], expression.isMichelsonEncodedString(), expression.humanReadableStringFromMichelson() != "" {
				delegate?.signRequested()
			} else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				delegateErrorOnMain(message: "error-unsupported-sign".localized(), error: nil)
			}
			
		} else if request.method == "tezos_getAccounts" {
			WalletConnectService.shared.respondWithAccounts()
			
		} else {
			WalletConnectService.rejectCurrentRequest(completion: nil)
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
	
	
	
	// MARK: - Pairing and WC2 responses
	
	@MainActor
	// TODO: move this into queue so that it happens after the current request
	public func pairClient(uri: WalletConnectURI) {
		Logger.app.info("WC pairing to \(uri.absoluteString)")
		Task {
			do {
				try await Pair.instance.pair(uri: uri)
				
			} catch {
				Logger.app.error("WC Pairing connect error: \(error)")
				delegateErrorOnMain(message: "Unable to connect to Pair with dApp, due to: \(error)", error: error)
			}
		}
	}
	
	public func respondWithAccounts() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC Approve Session error: Unable to find request")
			WalletConnectService.rejectCurrentRequest(completion: nil)
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
				requestDidComplete = true
				
			} catch {
				Logger.app.error("WC Approve Session error: \(error)")
				delegateErrorOnMain(message: "Wallet connect: error returning list of accounts: \(error)", error: error)
				requestDidComplete = false
			}
		}
	}
	
	
	
	
	
	/// WalletConnectService puts every user-action-required request into a queue, so that we can manage them 1 at a time. This function delays the marking of the current request as complete, by the given delay.
	/// Each bottom sheet has to deal with up to 2 dismissal animations (a fullscreen spinner / loader) followed by the sheet itself. Each of these should take the standard 0.3 to complete. We double that by default to ensure nothing goes wrong
	// TODO: could all bottom sheets move to showLoadingView instead of modal, so that its removal and the sheets dismissal can be done together, reducing this time
	public static func completeRequest(withDelay delay: TimeInterval = 1.2) {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
			WalletConnectService.shared.requestDidComplete = true
		}
	}
	
	/// Optional `andMarkComplete` needed for some internal situations where we can't continue on our side, so the queue will mark itself complete, but we still need to let WC2 know that something went wrong and the user might need to retry
	public static func rejectCurrentProposal(andMarkComplete: Bool = true, completion: ((Bool, Error?) -> Void)?) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			Logger.app.error("WC rejectCurrentProposal can't find current prposal")
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Reject proposal: \(proposal.id)")
		Task {
			do {
				try await Sign.instance.reject(proposalId: proposal.id, reason: .userRejected)
				Logger.app.info("WC rejectCurrentProposal success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC rejectCurrentProposal error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			if andMarkComplete { WalletConnectService.completeRequest() }
		}
	}
	
	public static func approveCurrentProposal(completion: ((Bool, Error?) -> Void)?) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal,
			  let currentAccount = DependencyManager.shared.selectedWalletMetadata,
			  let namespaces = WalletConnectService.createNamespace(forProposal: proposal, address: currentAccount.address, currentNetworkType: DependencyManager.shared.currentNetworkType) else {
			Logger.app.error("WC approveCurrentProposal can't find current prposal or current state")
			completion?(false, nil)
			return
		}
		
		let prefix = currentAccount.address.prefix(3).lowercased()
		var algo = ""
		if prefix == "tz1" {
			algo = "ed25519"
		} else if prefix == "tz2" {
			algo = "secp256k1"
		} else {
			algo = "unknown"
		}
		
		let sessionProperties = [
			"algo": algo,
			"address": currentAccount.address,
			"pubkey": currentAccount.bas58EncodedPublicKey
		]
		
		
		Logger.app.info("WC Approve proposal: \(proposal.id)")
		Task {
			do {
				try await Sign.instance.approve(proposalId: proposal.id, namespaces: namespaces, sessionProperties: sessionProperties)
				Logger.app.info("WC approveCurrentProposal success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC approveCurrentProposal error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			WalletConnectService.completeRequest()
		}
	}
	
	/// Optional `andMarkComplete` needed for some internal situations where we can't continue on our side, so the queue will mark itself complete, but we still need to let WC2 know that something went wrong and the user might need to retry
	public static func rejectCurrentRequest(withMessage: String = "", andMarkComplete: Bool = true, completion: ((Bool, Error?) -> Void)?) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC rejectCurrentRequest can't find current request")
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Reject request: \(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 0, message: withMessage)))
				Logger.app.info("WC rejectCurrentRequest success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC rejectCurrentRequest error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			if andMarkComplete { WalletConnectService.completeRequest() }
		}
	}
	
	public static func approveCurrentRequest(signature: String?, opHash: String?, completion: ((Bool, Error?) -> Void)?) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC approveCurrentRequest can't find current request or current state")
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Approve request: \(request.id)")
		Task {
			do {
				// Check whether response should be a signature or an opHash. Default to an error if none provided
				var response: RPCResult = RPCResult.error(.init(code: -1, message: "No signature or operation hash provided as response. UNable to determine success or failure of operation"))
				if let sig = signature {
					response = .response(AnyCodable(["signature": sig]))
					
				} else if let hash = opHash {
					response = .response(AnyCodable(any: hash))
				}
				
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: response)
				try? await Sign.instance.extend(topic: request.topic)
				Logger.app.info("WC approveCurrentRequest success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC approveCurrentRequest error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			WalletConnectService.completeRequest()
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
			WalletConnectService.rejectCurrentRequest(completion: nil)
			self.delegateErrorOnMain(message: "Unable to process wallet connect request", error: nil)
			return
		}
		
		guard let params = try? wcRequest.params.get(WalletConnectRequestParams.self), let wallet = WalletCacheService().fetchWallet(forAddress: params.account) else {
			WalletConnectService.rejectCurrentRequest(completion: nil)
			self.delegateErrorOnMain(message: "Unable to parse response or locate wallet", error: nil)
			return
		}
		
		TransactionService.shared.walletConnectOperationData.requestParams = params
		self.delegate?.processingIncomingOperations()
		
		// Map all wallet connect objects to kuaki objects
		let convertedOps = params.kukaiOperations()
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: convertedOps, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded()) { [weak self] result in
			guard let estimationResult = try? result.get() else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				self?.delegateErrorOnMain(message: "Unable to estimate fees", error: result.getFailure())
				return
			}
			
			self?.processTransactions(estimationResult: estimationResult, forWallet: wallet)
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
