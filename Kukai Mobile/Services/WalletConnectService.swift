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
	case batch
	case delegate
	case generic
}

public protocol WalletConnectServiceDelegate: AnyObject {
	func pairRequested()
	func signRequested()
	func processingIncomingOperations()
	func processingIncomingDone()
	func processedOperations(ofType: WalletConnectOperationType)
	func error(message: String?, error: Error?)
	func connectionStatusChanged(status: SocketConnectionStatus)
	func walletConnectSocketFailedToReconnect3Times()
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

/*
struct WC2CryptoProvider: CryptoProvider {
	
	func recoverPubKey(signature: WalletConnectSigner.EthereumSignature, message: Data) throws -> Data {
		return Data()
	}
	
	func keccak256(_ data: Data) -> Data {
		return data.sha3(.keccak256)
	}
}
*/

struct RequestOperation: Codable {
	let account: String
}

public class WalletConnectService {
	
	public static let shared = WalletConnectService()
	public var deepLinkPairingToConnect: WalletConnectURI? = nil
	public var hasBeenSetup = false
	public weak var delegate: WalletConnectServiceDelegate? = nil
	public var isConnected = false
	
	private var bag = [AnyCancellable]()
	private var connectionManagmentBag = [AnyCancellable]()
	private var tempConnectionSubscription: AnyCancellable? = nil
	private static let projectId = "97f804b46f0db632c52af0556586a5f3"
	private static let metadata = AppMetadata(name: "Kukai iOS",
											  description: "Kukai iOS",
											  url: "https://wallet.kukai.app",
											  icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"],
											  redirect: AppMetadata.Redirect(native: "kukai://", universal: nil))
	
	private var pairingTimer: Timer? = nil
	private var isReconnecting = false
	private var autoReconnectCount = 0
	private var isManualDisconnection = true
	
	@Published public var requestDidComplete: Bool = false
	@Published public var pairsAndSessionsUpdated: Bool = false
	
	/// This publisher serves as a means to combine WalletConnect's`sessionProposalPublisherSubject` and `sessionRequestPublisherSubject`,
	/// the subjects action output will either be a `WalletConnectSign.Session.Proposal` or a `WalletConnectSign.Request`.
	/// This will enable the ability to apply a buffer to all events that a user must interact with, so they can be presented/handled one at a time without the need for multiple async delays, guessing when everything is finished, and simplifying the code
	private let sessionActionRequiredPublisherSubject = PassthroughSubject<(action: Any, context: VerifyContext?), Never>()
	
	private init() {}
	
	public func setup() {
		
		// Objects and metadata
		Networking.configure(groupIdentifier: "group.app.kukai.mobile", projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory(), socketConnectionType: .manual)
		Pair.configure(metadata: WalletConnectService.metadata)
		//Sign.configure(crypto: WC2CryptoProvider())
		
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
			Logger.app.info("WC2 - Connection status: changed to \(status == .connected ? "connected" : "disconnected")")
			
			DispatchQueue.main.async {
				self?.delegate?.connectionStatusChanged(status: status)
			}
			
			if status == .disconnected {
				self?.isConnected = false
				
				if self?.isManualDisconnection == false && self?.isReconnecting == false {
					WalletConnectService.shared.reconnect()
					
				} else if self?.isManualDisconnection == true {
					self?.isManualDisconnection = false
				}
			} else {
				self?.isConnected = true
				
				if let uri = self?.deepLinkPairingToConnect {
					self?.pairClient(uri: uri)
				}
				
				self?.autoReconnectCount = 0
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
					
				} else if let uri = userActionItem.action as? WalletConnectURI {
					Logger.app.error("WC sessionActionRequiredPublisherSubject received a uri")
					return self.wrapPairRequestAsFuture(uri: uri)
					
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
				
				self?.delegate?.processingIncomingDone()
				self?.pairingTimer?.invalidate()
				self?.pairingTimer = nil
				
			}.store(in: &bag)
		
		Sign.instance.sessionRequestPublisher
			.sink { [weak self] incomingProposalObj in
				Logger.app.info("WC sessionRequestPublisher")
				self?.sessionActionRequiredPublisherSubject.send((action: incomingProposalObj.request, context: incomingProposalObj.context))
				
			}.store(in: &bag)
		
		
		hasBeenSetup = true
		
		/*
		if let uri = deepLinkPairingToConnect {
			pairClient(uri: uri)
		}
		*/
	}
	
	public func connect() {
		if !hasBeenSetup { return }
		Logger.app.info("WC2 - Connection status: calling connect()")
		
		self.connectionManagmentBag.forEach({ $0.cancel() })
		self.reconnect()
	}
	
	public func disconnect() {
		if !hasBeenSetup { return }
		Logger.app.info("WC2 - Connection status: calling disconnect()")
		
		self.isManualDisconnection = true
		
		self.connectionManagmentBag.forEach({ $0.cancel() })
		try? Networking.instance.disconnect(closeCode: .normalClosure)
	}
	
	public func reconnect() {
		Logger.app.info("WC2 - Connection status: calling reconnect()")
		isReconnecting = true
		autoReconnectCount += 1
		
		// Listen for connection events and return when complete, keep retrying if not
		Networking.instance.socketConnectionStatusPublisher.dropFirst().sink { [weak self] value in
			
			if value == .connected {
				Logger.app.info("WC2 - Connection status: reconnect reporting success")
				
				self?.connectionManagmentBag.forEach({ $0.cancel() })
				self?.isReconnecting = false
				
			} else {
				Logger.app.info("WC2 - Connection status: reconnect reporting failure, retrying in 3 seconds")
				
				self?.retryReconnect()
			}
			
		}.store(in: &connectionManagmentBag)
		
		
		// perform a disconnect and then try to connect
		do {
			try Networking.instance.disconnect(closeCode: .normalClosure)
			try Networking.instance.connect()
			
		} catch (let error) {
			Logger.app.info("WC2 - Connection status: reconnect reporting error: \(error)")
			self.retryReconnect()
		}
	}
	
	private func retryReconnect() {
		if self.autoReconnectCount < 3 {
			DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2) {
				WalletConnectService.shared.reconnect()
			}
		} else {
			Logger.app.info("WC2 - Connection status: reconnect attempts exceeded. Cancelling for now")
			self.autoReconnectCount = 0
			self.delegate?.walletConnectSocketFailedToReconnect3Times()
		}
	}

	
	
	
	// MARK: - Queue Management
	
	private func wrapProposalAsFuture(proposal: Session.Proposal) -> Future<Bool, Never> {
		return Future<Bool, Never>() { [weak self] promise in
			Logger.app.info("Processing WC2 proposal: \(proposal.id)")
			TransactionService.shared.walletConnectOperationData.proposal = proposal
			
			guard let self = self else {
				Logger.app.error("WC wrapProposalAsFuture failed to find self, returning false")
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "error-wc2-cant-continue".localized(), error: nil)
				promise(.success(false))
				return
			}
			
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
			Logger.app.info("Processing WC2 request method: \(request.method), for topic: \(request.topic), with id: \(request.id)")
			TransactionService.shared.walletConnectOperationData.request = request
			
			guard let self = self else {
				Logger.app.error("WC wrapRequestAsFuture failed to find self, returning false")
				WalletConnectService.rejectCurrentRequest(andMarkComplete: false, completion: nil)
				self?.delegateErrorOnMain(message: "error-wc2-cant-continue".localized(), error: nil)
				promise(.success(false))
				return
			}
			
			if request.method != "tezos_getAccounts" {
				self.delegate?.processingIncomingOperations()
			}
			
			// Check if the request is for the correct network, and requesting for the correct account
			// TODO: The tezos provider should be performing the account check at a minimum, when the provider is replaced, remove this check
			self.checkValidNetworkAndAccount(forRequest: request) { [weak self] isValid in
				
				guard isValid else {
					Logger.app.info("Request is for the wrong network, rejecting")
					promise(.success(false))
					return
				}
				
				// Process the request
				self?.handleRequestLogic(request)
			}
			
			
			// Setup listener for completion status
			self.$requestDidComplete
				.dropFirst()
				.sink(receiveValue: { value in
					promise(.success(value))
				})
				.store(in: &self.bag)
		}
	}
	
	private func wrapPairRequestAsFuture(uri: WalletConnectURI) -> Future<Bool, Never> {
		return Future<Bool, Never>() { [weak self] promise in
			Logger.app.info("WC pairing to \(uri.absoluteString)")
			
			self?.delegate?.processingIncomingOperations()
			self?.pairingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { [weak self] timer in
				self?.delegateErrorOnMain(message: "No response from application. Please refresh the webpage, and try to connect again", error: nil)
				self?.delegate?.processingIncomingDone()
			})
			
			Task { [weak self] in
				do {
					try await Pair.instance.pair(uri: uri)
					promise(.success(true))
					
				} catch {
					Logger.app.error("WC Pairing connect error: \(error)")
					self?.delegateErrorOnMain(message: "Unable to connect to Pair with dApp, due to: \(error)", error: error)
					self?.delegate?.processingIncomingDone()
					self?.pairingTimer?.invalidate()
					self?.pairingTimer = nil
					promise(.success(false))
				}
				
				self?.deepLinkPairingToConnect = nil
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
			WalletConnectService.shared.respondWithAccounts(request: request)
			
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
			//let accounts = [wcAccount]
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
			//tezosNamespace?.accounts = [newAccount]
		}
		
		if let namespace = tezosNamespace {
			return ["tezos": namespace]
		}
		
		return nil
	}
	
	
	
	// MARK: - Pairing and WC2 responses
	
	/// Due to Beacon incorrectly triggering this all incoming uri's get treated the same as a incoming proposal or a request.
	/// The URI pairing function is wrapped up inside a Future and passed into the user action queue, to ensure only 1 thing is processed at a time
	public func pairClient(uri: WalletConnectURI) {
		self.sessionActionRequiredPublisherSubject.send((action: uri, context: nil))
	}
	
	public func respondWithAccounts(request: WalletConnectSign.Request) {
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
				
				// This gets trigger after an account switch, which may result in the dApp asking for details of an address that is not the currently selected address
				// Instead search for the stored session properties of the linked session and return details for that address instead. if It exists, fallback to selected
				var metadataToUse = DependencyManager.shared.selectedWalletMetadata
				if let relatedSession = Sign.instance.getSessions().filter({ $0.topic == request.topic }).first,
				   let addressUsedInSession = relatedSession.namespaces["tezos"]?.accounts.first?.address,
				   let metadataForAddress = DependencyManager.shared.walletList.metadata(forAddress: addressUsedInSession) {
					metadataToUse = metadataForAddress
				}
				
				let prefix = metadataToUse?.address.prefix(3).lowercased() ?? ""
				var algo = ""
				if prefix == "tz1" {
					algo = "ed25519"
				} else if prefix == "tz2" {
					algo = "secp256k1"
				} else {
					algo = "unknown"
				}
				
				let obj = WalletConnectGetAccountObj(algo: algo, address: metadataToUse?.address ?? "", pubkey: metadataToUse?.bas58EncodedPublicKey ?? "")
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable([obj])))
				WalletConnectService.completeRequest(withDelay: 0.3)
				
			} catch {
				Logger.app.error("WC Approve Session error: \(error)")
				delegateErrorOnMain(message: "Wallet connect: error returning list of accounts: \(error)", error: error)
				WalletConnectService.completeRequest(withDelay: 0.3, withValue: false)
			}
		}
	}
	
	
	
	
	
	/// WalletConnectService puts every user-action-required request into a queue, so that we can manage them 1 at a time. This function delays the marking of the current request as complete, by the given delay.
	/// Each bottom sheet has to deal with up to 2 dismissal animations (a fullscreen spinner / loader) followed by the sheet itself. Each of these should take the standard 0.3 to complete. We double that by default to ensure nothing goes wrong
	// TODO: could all bottom sheets move to showLoadingView instead of modal, so that its removal and the sheets dismissal can be done together, reducing this time
	public static func completeRequest(withDelay delay: TimeInterval = 1.2, withValue value: Bool = true) {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
			WalletConnectService.shared.requestDidComplete = value
		}
	}
	
	/// Optional `andMarkComplete` needed for some internal situations where we can't continue on our side, so the queue will mark itself complete, but we still need to let WC2 know that something went wrong and the user might need to retry
	public static func rejectCurrentProposal(andMarkComplete: Bool = true, completion: ((Bool, Error?) -> Void)?) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			Logger.app.error("WC rejectCurrentProposal can't find current prposal")
			if andMarkComplete { WalletConnectService.completeRequest() }
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Reject proposal: \(proposal.id)")
		Task {
			do {
				//try await Sign.instance.rejectSession(proposalId: proposal.id, reason: .userRejected)
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
		let selectedAccountMeta = DependencyManager.shared.temporarySelectedWalletMetadata == nil ? DependencyManager.shared.selectedWalletMetadata : DependencyManager.shared.temporarySelectedWalletMetadata
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal,
			  let currentAccount = selectedAccountMeta,
			  let namespaces = WalletConnectService.createNamespace(forProposal: proposal, address: currentAccount.address, currentNetworkType: DependencyManager.shared.currentNetworkType) else {
			Logger.app.error("WC approveCurrentProposal can't find current prposal or current state")
			WalletConnectService.completeRequest()
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
				let _ = try await Sign.instance.approve(proposalId: proposal.id, namespaces: namespaces, sessionProperties: sessionProperties)
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
	public static func rejectCurrentRequest(withMessage: String = "User Rejected", andMarkComplete: Bool = true, completion: ((Bool, Error?) -> Void)?) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC rejectCurrentRequest can't find current request")
			if andMarkComplete { WalletConnectService.completeRequest() }
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
			WalletConnectService.completeRequest()
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
					response = .response(AnyCodable(["operationHash": hash]))
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
	
	// Central place to act somewhat as a viewModel to parse the incoming payload and add some hints to TransactionService on how to display it
	private func processTransactions(estimationResult: FeeEstimatorService.EstimationResult, forWallet: Wallet) {
		let operationsObj = TransactionService.OperationsAndFeesData(estimatedOperations: estimationResult.operations)
		let operations = operationsObj.selectedOperationsAndFees()
		
		TransactionService.shared.currentRemoteOperationsAndFeesData = operationsObj
		TransactionService.shared.currentRemoteForgedString = estimationResult.forgedString
		
		DependencyManager.shared.tezosNodeClient.getBalance(forAddress: forWallet.address) { [weak self] res in
			let xtzBalance = (try? res.get()) ?? .zero()
			let xtzSend = OperationFactory.Extractor.totalTezAmountSent(operations: operations)
			
			if (xtzSend + operationsObj.fee) > xtzBalance {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				self?.delegateErrorOnMain(message: String.localized("error-funds-body-wc2", withArguments: forWallet.address.truncateTezosAddress(), xtzBalance.normalisedRepresentation, (xtzSend + operationsObj.fee).normalisedRepresentation), error: nil)
				
			} else {
				self?.processTransactionsAfterBalance(operationsObj: operationsObj, operations: operations, forWallet: forWallet, xtzBalance: xtzBalance)
			}
		}
	}
	
	private func processTransactionsAfterBalance(operationsObj: TransactionService.OperationsAndFeesData, operations: [KukaiCoreSwift.Operation], forWallet: Wallet, xtzBalance: XTZAmount) {
		
		if let op = OperationFactory.Extractor.isTezTransfer(operations: operations) {
			let xtzAmount = XTZAmount(fromRpcAmount: op.amount) ?? .zero()
			let accountBalance = xtzBalance
			let selectedToken = Token.xtz(withAmount: accountBalance)
			
			TransactionService.shared.walletConnectOperationData.currentTransactionType = .send
			TransactionService.shared.walletConnectOperationData.sendData.chosenToken = selectedToken
			TransactionService.shared.walletConnectOperationData.sendData.chosenAmount = xtzAmount
			TransactionService.shared.walletConnectOperationData.sendData.destination = op.destination
			mainThreadProcessedOperations(ofType: .sendToken)
			
		} else if let result = OperationFactory.Extractor.isFaTokenTransfer(operations: operations), let token = DependencyManager.shared.balanceService.token(forAddress: result.tokenContract, andTokenId: result.tokenId) {
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
			
		} else if let delegateOperation = OperationFactory.Extractor.isDelegate(operations: operations) {
			DependencyManager.shared.tzktClient.bakers { [weak self] result in
				guard let res = try? result.get() else {
					self?.checkForBaker(delegateOperation: delegateOperation, bakers: nil)
					return
				}
				
				self?.checkForBaker(delegateOperation: delegateOperation, bakers: res)
			}
			
		} else if OperationFactory.Extractor.containsAnUnknownOperation(operations: operations) {
			mainThreadProcessedOperations(ofType: .generic)
			
		} else {
			
			// Compute opSummaries for Batch UI
			var opSummaries: [TransactionService.BatchOpSummary] = []
			var previousEmptyToken: Token? = nil
			
			for op in operations {
				
				var summary = TransactionService.BatchOpSummary(chosenToken: nil, chosenAmount: nil, contractAddress: nil, mainEntrypoint: nil)
				if let opTrans = op as? OperationTransaction {
					
					// Loop through each op and see is it a transaction operation, if so does it send XTZ or a token, if so record it
					let totalXTZ = OperationFactory.Extractor.totalTezAmountSent(operations: [opTrans])
					if totalXTZ > XTZAmount.zero() {
						summary.chosenToken = Token.xtz()
						summary.chosenAmount = totalXTZ
						
					} else if let firstTokenDetails = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: [opTrans]) {
						
						var token: Token? = nil
						if let t = DependencyManager.shared.balanceService.dexToken(forAddress: firstTokenDetails.tokenContract, andTokenId: firstTokenDetails.tokenId) {
							token = t
							
						} else if let t = DependencyManager.shared.balanceService.token(forAddress: firstTokenDetails.tokenContract, andTokenId: firstTokenDetails.tokenId) {
							token = t.token
							
						} else {
							token = Token(name: nil,
										  symbol: "",
										  tokenType: .fungible,
										  faVersion: firstTokenDetails.tokenId != nil ? .fa2 : .fa1_2,
										  balance: TokenAmount.zeroBalance(decimalPlaces: 0),
										  thumbnailURL: TzKTClient.avatarURL(forToken: firstTokenDetails.tokenContract),
										  tokenContractAddress: firstTokenDetails.tokenContract,
										  tokenId: 0,
										  nfts: nil,
										  mintingTool: nil)
						}
						
						if firstTokenDetails.rpcAmount == "" || firstTokenDetails.rpcAmount == "0" {
							
							// When doing 3Route calls, the tokenId is only available in the first op, and the amount in the second
							// So if we got a token, but no amount, ignore it for now and hold onto it
							previousEmptyToken = token
							
						} else {
							
							// If we have a token and an amount, check to see if we are missing any info from token, and apply it from `previousEmptyToken` if possible
							// Then make sure we compute tokenAmount again, to make sure it reflects decimals etc
							if token?.symbol == "" && previousEmptyToken?.symbol != nil && previousEmptyToken?.symbol != "" {
								summary.chosenToken = previousEmptyToken
								summary.chosenAmount = TokenAmount(fromRpcAmount: firstTokenDetails.rpcAmount, decimalPlaces: previousEmptyToken?.decimalPlaces ?? 0)
							} else {
								summary.chosenToken = token
								summary.chosenAmount = TokenAmount(fromRpcAmount: firstTokenDetails.rpcAmount, decimalPlaces: token?.decimalPlaces ?? 0)
							}
						}
					}
					
					// Also check for contract call details
					if let contractDetails = OperationFactory.Extractor.isContractCall(operation: opTrans) {
						summary.contractAddress = contractDetails.address
						summary.mainEntrypoint = contractDetails.entrypoint
					} else {
						summary.contractAddress = forWallet.address // If theres no contract address, its likely an action such as reveal or delegate where you perform an operation on your own account
					}
					
				} else {
					
					// If its not an OperationTransaction, add something to the summary.contractAddress to act as a display string
					switch op.operationKind {
						case .delegation:
							summary.contractAddress = (op as? OperationDelegation)?.delegate ?? forWallet.address
							
						default:
							summary.contractAddress = forWallet.address
					}
				}
				
				summary.operationTypeString = op.operationKind.rawValue
				opSummaries.append(summary)
			}
			
			// Add rest of required data to batch data
			TransactionService.shared.walletConnectOperationData.batchData.opSummaries = opSummaries
			TransactionService.shared.walletConnectOperationData.batchData.operationCount = operations.count
			TransactionService.shared.walletConnectOperationData.currentTransactionType = .batch
			
			
			
			
			
			// Above we run `firstNonZeroTokenTransferAmount` on each operation to extract some pieces of information from each operation.
			// it was intended to run on an array of operations, but the operation details screen needs similar data for each op.
			// The "full picture" can only be seen with access to all of them. So here we re-run it again against everything to try and
			// get the full picture of FA token sends, if we currently have no XTZ send to deal with
			
			var xtzAmount = XTZAmount.zero()
			opSummaries.forEach { summary in
				if summary.chosenToken?.isXTZ() == true {
					xtzAmount += (summary.chosenAmount as? XTZAmount) ?? .zero()
				}
			}
			
			let accountBalance = xtzBalance
			let selectedToken = Token.xtz(withAmount: accountBalance)
			
			TransactionService.shared.walletConnectOperationData.batchData.mainDisplayToken = selectedToken
			TransactionService.shared.walletConnectOperationData.batchData.mainDisplayAmount = xtzAmount
			mainThreadProcessedOperations(ofType: .batch)
			
			// TODO: disabling the token identification abstraction logic for now. More testing needed
			/*
			if xtzAmount > XTZAmount.zero() {
				
				// show XTZ amount
				let accountBalance = xtzBalance
				let selectedToken = Token.xtz(withAmount: accountBalance)
				
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayToken = selectedToken
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayAmount = xtzAmount
				mainThreadProcessedOperations(ofType: .batch)
				
			} else if let globalDetails = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: operations), globalDetails.rpcAmount != "", globalDetails.rpcAmount != "0" {
				
				// process token details
				var token: Token? = nil
				
				if let t = DependencyManager.shared.balanceService.dexToken(forAddress: globalDetails.tokenContract, andTokenId: globalDetails.tokenId) {
					token = t
					
				} else if let t = DependencyManager.shared.balanceService.token(forAddress: globalDetails.tokenContract, andTokenId: globalDetails.tokenId) {
					token = t.token
					
				} else {
					token = Token(name: nil,
								  symbol: "",
								  tokenType: .fungible,
								  faVersion: globalDetails.tokenId != nil ? .fa2 : .fa1_2,
								  balance: TokenAmount.zeroBalance(decimalPlaces: 0),
								  thumbnailURL: TzKTClient.avatarURL(forToken: globalDetails.tokenContract),
								  tokenContractAddress: globalDetails.tokenContract,
								  tokenId: 0,
								  nfts: nil,
								  mintingTool: nil)
				}
				
				let amount = TokenAmount(fromRpcAmount: globalDetails.rpcAmount, decimalPlaces: token?.decimalPlaces ?? 0)
				
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayToken = token
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayAmount = amount
				mainThreadProcessedOperations(ofType: .batch)
				
			} else {
				let accountBalance = xtzBalance
				let selectedToken = Token.xtz(withAmount: accountBalance)
				
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayToken = selectedToken
				TransactionService.shared.walletConnectOperationData.batchData.mainDisplayAmount = XTZAmount.zero()
				mainThreadProcessedOperations(ofType: .batch)
			}
			*/
		}
	}
	
	private func checkForBaker(delegateOperation: OperationDelegation, bakers: [TzKTBaker]?) {
		if delegateOperation.delegate == nil {
			TransactionService.shared.delegateData.isAdd = false
			
			if let currentDelegate = DependencyManager.shared.balanceService.account.delegate {
				
				if let matchingBaker = (bakers ?? []).filter({ $0.address == currentDelegate.address }).first {
					TransactionService.shared.delegateData.chosenBaker = matchingBaker
				} else {
					let baker = TzKTBaker(address: currentDelegate.address, name: currentDelegate.alias ?? currentDelegate.address.truncateTezosAddress(), logo: nil)
					TransactionService.shared.delegateData.chosenBaker = baker
				}
				
			} else {
				let baker = TzKTBaker(address: "", name: "", logo: nil)
				TransactionService.shared.delegateData.chosenBaker = baker
			}
			
		} else {
			TransactionService.shared.delegateData.isAdd = true
			let operationAddress = delegateOperation.delegate ?? ""
			
			if let matchingBaker = (bakers ?? []).filter({ $0.address == (operationAddress) }).first {
				TransactionService.shared.delegateData.chosenBaker = matchingBaker
				
			} else {
				let baker = TzKTBaker(address: operationAddress, name: operationAddress.truncateTezosAddress(), logo: nil)
				TransactionService.shared.delegateData.chosenBaker = baker
			}
		}
		
		mainThreadProcessedOperations(ofType: .delegate)
	}
	
	private func mainThreadProcessedOperations(ofType type: WalletConnectOperationType) {
		DispatchQueue.main.async { [weak self] in
			self?.delegate?.processedOperations(ofType: type)
		}
	}
}
