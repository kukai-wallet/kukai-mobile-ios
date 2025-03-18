//
//  WalletConnectService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/02/2023.
//

import Foundation
import KukaiCoreSwift
import Starscream
import ReownWalletKit
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
}

public struct WalletConnectGetAccountObj: Codable {
	let algo: String
	let address: String
	let pubkey: String
}

extension WebSocket: @retroactive WebSocketConnecting {}

struct DefaultSocketFactory: WebSocketFactory {
	
	func create(with url: URL) -> WebSocketConnecting {
		let socket = WebSocket(url: url)
		let queue = DispatchQueue(label: "com.walletconnect.sdk.sockets", attributes: .concurrent)
		socket.callbackQueue = queue
		return socket
	}
}

struct WC2CryptoProvider: CryptoProvider {
	
	func recoverPubKey(signature: WalletConnectSigner.EthereumSignature, message: Data) throws -> Data {
		return Data()
	}
	
	func keccak256(_ data: Data) -> Data {
		return ((try? data.sha3(varient: .KECCAK256)) ?? Data())
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
	public var isConnected = false
	
	private var bag = [AnyCancellable]()
	private static let projectId = "97f804b46f0db632c52af0556586a5f3"
	
	private var pairingTimer: Timer? = nil
	private var requestOrProposalInProgress = false
	private typealias walletConnectRequestTuple = (request: Request, context: VerifyContext?)
	private typealias walletConnectPorposalTuple = (proposal: Session.Proposal, context: VerifyContext?)
	
	@Published public var sessionsUpdated: Bool = false
	
	private init() {}
	
	public func setup(force: Bool = false) {
		guard !hasBeenSetup || force else {
			return
		}
		
		bag.removeAll()
		
		// Setup redirect for release only, so beta doesn't interact with it
		#if BETA
		guard let redirect = try? AppMetadata.Redirect(native: "", universal: nil) else {
			return
		}
		Networking.configure(groupIdentifier: "group.app.kukai.mobile.beta", projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory(), socketConnectionType: .automatic)
		
		#elseif DEBUG
		guard let redirect = try? AppMetadata.Redirect(native: "", universal: nil) else {
			return
		}
		Networking.configure(groupIdentifier: "group.app.kukai.mobile.dev", projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory(), socketConnectionType: .automatic)
		
		#else
		guard let redirect = try? AppMetadata.Redirect(native: "kukai://", universal: "https://connect.kukai.app", linkMode: true) else {
			return
		}
		Networking.configure(groupIdentifier: "group.app.kukai.mobile", projectId: WalletConnectService.projectId, socketFactory: DefaultSocketFactory(), socketConnectionType: .automatic)
		
		#endif
		
		
		// Objects and metadata
		let metadata = AppMetadata(name: "Kukai iOS", description: "Kukai iOS", url: "https://wallet.kukai.app", icons: ["https://wallet.kukai.app/assets/img/header-logo.svg"], redirect: redirect)
		WalletKit.configure(metadata: metadata, crypto: WC2CryptoProvider())
		Events.instance.setTelemetryEnabled(false)
		
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { status in
			Logger.app.info("WC2 - Connection status: changed to \(status == .connected ? "connected" : "disconnected")")
			WalletConnectService.shared.isConnected = status == .connected
			
			DispatchQueue.main.async {
				WalletConnectService.shared.delegate?.connectionStatusChanged(status: status)
			}
			
		}.store(in: &bag)
		
		
		// Callbacks
		WalletKit.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { data in
				Logger.app.info("WC sessionSettlePublisher \(data.topic)")
			}.store(in: &bag)
		
		WalletKit.instance.sessionDeletePublisher
			.receive(on: DispatchQueue.main)
			.sink { [weak self] data in 
				Logger.app.info("WC sessionDeletePublisher \(data.0)")
				self?.sessionsUpdated = true
			}.store(in: &bag)
		
		// Pass WC2 objects to central buffered publisher, as they require identical UI/UX management (displying bottom sheet, requesting user interaction)
		WalletKit.instance.sessionProposalPublisher
			.sink { [weak self] incomingProposalObj in
				Logger.app.info("WC sessionProposalPublisher")
				self?.handleRequestOrProposal()
				
				self?.delegate?.processingIncomingDone()
				self?.pairingTimer?.invalidate()
				self?.pairingTimer = nil
				
			}.store(in: &bag)
		
		WalletKit.instance.sessionRequestPublisher
			.sink { [weak self] incomingProposalObj in
				Logger.app.info("WC sessionRequestPublisher")
				self?.handleRequestOrProposal()
			}.store(in: &bag)
		
		
		hasBeenSetup = true
		
		if let uri = deepLinkPairingToConnect {
			pairClient(uri: uri)
		}
	}
	
	
	
	// MARK: - Queue Management
	
	private func handleRequestOrProposal() {
		guard !requestOrProposalInProgress else {
			return
		}
		
		if let nextRequest = WalletKit.instance.getPendingRequests().first {
			requestOrProposalInProgress = true
			handleRequest(nextRequest)
			
		} else if let nextProposal = WalletKit.instance.getPendingProposals().first {
			requestOrProposalInProgress = true
			handleProposal(nextProposal)
			
		} else {
			Logger.app.error("handleRequestOrProposal but nothing here")
			requestOrProposalInProgress = false
		}
	}
	
	private func handleRequest(_ requestWrapper: walletConnectRequestTuple) {
		Logger.app.info("Processing WC2 request method: \(requestWrapper.request.method), for topic: \(requestWrapper.request.topic), with id: \(requestWrapper.request.id)")
		TransactionService.shared.walletConnectOperationData.request = requestWrapper.request
		
		guard let _ = TransactionService.shared.walletConnectOperationData.request else {
			WalletConnectService.rejectCurrentRequest(completion: nil)
			delegateErrorOnMain(message: "error-wc2-invalid-request".localized(), error: nil)
			return
		}
		
		if requestWrapper.request.method != "tezos_getAccounts" {
			self.delegate?.processingIncomingOperations()
		}
		
		// Check if the request is for the correct network, and requesting for the correct account
		// TODO: The tezos provider should be performing the account check at a minimum, when the provider is replaced, remove this check
		self.checkValidNetworkAndAccount(forRequest: requestWrapper.request) { [weak self] isValid in
			
			guard isValid else {
				Logger.app.info("Request is for the wrong network, rejecting")
				return
			}
			
			// Process the request
			self?.handleRequestLogic(requestWrapper.request)
		}
	}
	
	private func handleProposal(_ proposalWrapper: walletConnectPorposalTuple) {
		Logger.app.info("Processing WC2 proposal: \(proposalWrapper.proposal.id)")
		TransactionService.shared.walletConnectOperationData.proposal = proposalWrapper.proposal
		
		guard let _ = TransactionService.shared.walletConnectOperationData.proposal else {
			WalletConnectService.rejectCurrentProposal(completion: nil)
			delegateErrorOnMain(message: "error-wc2-invalid-proposal".localized(), error: nil)
			return
		}
		
		// Check if the proposal is for the network the app is currently on
		self.checkValidNetwork(forProposal: proposalWrapper.proposal) { [weak self] isValid in
			guard isValid else {
				Logger.app.info("Request is for the wrong network, rejecting")
				return
			}
			
			self?.delegate?.pairRequested()
		}
	}
	
	/// Check if the proposal network matches the current one the app is pointing too. Return false in completion block if its not, and fire off a message to delegate error hanlder if so. Calling code only needs to check for if true
	private func checkValidNetwork(forProposal proposal: WalletConnectSign.Session.Proposal, completion: @escaping ((Bool) -> Void)) {
		DependencyManager.shared.tezosNodeClient.getNetworkInformation { [weak self] _, error in
			if let err = error {
				WalletConnectService.rejectCurrentProposal(completion: nil)
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
				WalletConnectService.rejectCurrentProposal(completion: nil)
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
				WalletConnectService.rejectCurrentRequest(completion: nil)
				self?.delegateErrorOnMain(message: "Unable to fetch info from the Tezos node, please try again", error: err)
				completion(false)
				return
			}
			
			
			// Check the chain is the current chain
			guard let tezosChainName = DependencyManager.shared.tezosNodeClient.networkVersion?.chainName(),
				  (request.chainId.absoluteString == "tezos:\(tezosChainName)" || (request.chainId.absoluteString == "tezos:ghostnet" && tezosChainName == "ithacanet"))
			else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				let onDevice = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
				self?.delegateErrorOnMain(message: "Request is for a different network than the one currently selected on device (\"\(onDevice)\"). Please check the dApp and apps settings to match sure they match", error: nil)
				completion(false)
				return
			}
			
			
			// Check the requested account and method were previously allowed
			let session = WalletKit.instance.getSessions().filter({ $0.topic == request.topic }).first
			let allowedAccounts = session?.namespaces["tezos"]?.accounts.map({ $0.absoluteString }) ?? []
			let allowedMethods = session?.namespaces["tezos"]?.methods ?? []
			
			let requestedAccount = (try? request.params.get(RequestOperation.self).account) ?? ""
			let normalisedChainName = (tezosChainName == "ithacanet") ? "ghostnet" : tezosChainName
			let fullRequestedAccount = "tezos:\(normalisedChainName):\(requestedAccount)"
			let requestedMethod = request.method
			
			guard requestedMethod == "tezos_getAccounts" || allowedAccounts.contains(fullRequestedAccount) else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
				self?.delegateErrorOnMain(message: "The requested account \(requestedAccount.truncateTezosAddress()), was not authorised to perform this action. Please ensure you have paired this account with the remote application.", error: nil)
				completion(false)
				return
			}
			
			guard allowedMethods.contains(requestedMethod) else {
				WalletConnectService.rejectCurrentRequest(completion: nil)
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
			let accounts = [wcAccount]
			let sessionNamespace = SessionNamespace(accounts: accounts, methods: approvedMethods ?? [], events: approvedEvents ?? [])
			sessionNamespaces["tezos"] = sessionNamespace
			
			return sessionNamespaces
			
		} else {
			return nil
		}
	}
	
	public static func updateNamespaces(forSession session: Session, toAddress: String/*, andNetwork newNetwork: TezosNodeClientConfig.NetworkType*/) -> [String: SessionNamespace]? {
		var tezosNamespace = session.namespaces["tezos"]
		
		let previousNetwork = tezosNamespace?.accounts.first?.blockchain.reference ?? (DependencyManager.shared.currentNetworkType == .mainnet ? "mainnet" : "ghostnet")
		if let newAccount = Account("tezos:\(previousNetwork):\(toAddress)") {
			tezosNamespace?.accounts = [newAccount]
		}
		
		if let namespace = tezosNamespace {
			return ["tezos": namespace]
		}
		
		return nil
	}
	
	
	
	// MARK: - Pairing and WC2 responses
	
	public func pairClient(uri: WalletConnectURI) {
		guard !requestOrProposalInProgress else {
			Logger.app.error("WC Pairing blocked by pending operations")
			self.delegateErrorOnMain(message: "Please wait until all pending requests are finished before attempting a new pairing", error: nil)
			return
		}
		
		self.delegate?.processingIncomingOperations()
		self.pairingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { [weak self] timer in
			Logger.app.error("WC Pairing cancelled due to timeout")
			self?.delegateErrorOnMain(message: "No response from application. Please refresh the webpage, and try to connect again", error: nil)
			self?.delegate?.processingIncomingDone()
		})
		
		Task { [weak self] in
			do {
				try await WalletKit.instance.pair(uri: uri)
				
			} catch {
				Logger.app.error("WC Pairing connect error: \(error)")
				self?.delegateErrorOnMain(message: "Unable to connect to Pair with dApp, due to: \(error)", error: error)
				self?.delegate?.processingIncomingDone()
				self?.pairingTimer?.invalidate()
				self?.pairingTimer = nil
			}
			
			self?.deepLinkPairingToConnect = nil
		}
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
				if let relatedSession = WalletKit.instance.getSessions().filter({ $0.topic == request.topic }).first,
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
				try await WalletKit.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable([obj])))
				WalletConnectService.completeRequest(withDelay: 0.3)
				
			} catch {
				Logger.app.error("WC Approve Session error: \(error)")
				delegateErrorOnMain(message: "Wallet connect: error returning list of accounts: \(error)", error: error)
				WalletConnectService.completeRequest(withDelay: 0.3, withValue: false)
			}
		}
	}
	
	
	
	
	/// Previously this function managed the termintation of events in our own queue system. Seems to be no longer necessary. Leaving the definition as is for now incase we need to revert back
	public static func completeRequest(withDelay delay: TimeInterval = 0.3, withValue value: Bool = true) {
		WalletConnectService.shared.requestOrProposalInProgress = false
	}
	
	/// Optional `andMarkComplete` needed for some internal situations where we can't continue on our side, so the queue will mark itself complete, but we still need to let WC2 know that something went wrong and the user might need to retry
	public static func rejectCurrentProposal(completion: ((Bool, Error?) -> Void)?) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			Logger.app.error("WC rejectCurrentProposal can't find current prposal")
			WalletConnectService.completeRequest()
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Reject proposal: \(proposal.id)")
		Task {
			do {
				try await WalletKit.instance.rejectSession(proposalId: proposal.id, reason: .userRejected)
				Logger.app.info("WC rejectCurrentProposal success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC rejectCurrentProposal error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			WalletConnectService.completeRequest()
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
				let _ = try await WalletKit.instance.approve(proposalId: proposal.id, namespaces: namespaces, sessionProperties: sessionProperties)
				Logger.app.info("WC approveCurrentProposal success")
				WalletConnectService.shared.sessionsUpdated = true
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
	public static func rejectCurrentRequest(withMessage: String = "User Rejected", completion: ((Bool, Error?) -> Void)?) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			Logger.app.error("WC rejectCurrentRequest can't find current request")
			WalletConnectService.completeRequest()
			completion?(false, nil)
			return
		}
		
		Logger.app.info("WC Reject request: \(request.id)")
		Task {
			do {
				try await WalletKit.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 0, message: withMessage)))
				Logger.app.info("WC rejectCurrentRequest success")
				completion?(true, nil)
				
			} catch (let error) {
				Logger.app.error("WC rejectCurrentRequest error: \(error)")
				completion?(false, error)
			}
			
			TransactionService.shared.resetWalletConnectState()
			WalletConnectService.completeRequest()
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
				
				try await WalletKit.instance.respond(topic: request.topic, requestId: request.id, response: response)
				try? await WalletKit.instance.extend(topic: request.topic)
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
	
	
	
	
	
	// TODO: remove these when 1.2.0 allows us to access the updated version of kukaiCoreSwift
	/**
	 Filter and verify only 1 transaction exists thats performing an unstake operation. If so return this operation, otherwise return nil
	 */
	private static func temp_isUnstake(operations: [KukaiCoreSwift.Operation]) -> OperationTransaction? {
		let filteredOperations = OperationFactory.Extractor.filterReveal(operations: operations)
		if filteredOperations.count == 1,
		   let op = filteredOperations.first as? OperationTransaction,
		   op.parameters?["entrypoint"] as? String == "unstake",
		   let valueDict = op.parameters?["value"] as? [String: String],
		   Array(valueDict.keys) == ["prim"],
		   Array(valueDict.values) == ["Unit"]
		{
			return op
		}
		
		return nil
	}
	
	/**
	 Filter and verify only 1 transaction exists thats performing a finalise unstake operation If so return this operation, otherwise return nil
	 */
	private static func temp_isFinaliseUnstake(operations: [KukaiCoreSwift.Operation]) -> OperationTransaction? {
		let filteredOperations = OperationFactory.Extractor.filterReveal(operations: operations)
		if filteredOperations.count == 1,
		   let op = filteredOperations.first as? OperationTransaction,
		   op.parameters?["entrypoint"] as? String == "finalize_unstake",
		   let valueDict = op.parameters?["value"] as? [String: String],
		   Array(valueDict.keys) == ["prim"],
		   Array(valueDict.values) == ["Unit"]
		{
			return op
		}
		
		return nil
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
			
			// Pop up XTZ lack of funds warning error, only if its not a unstake, or finalise_unstake operation, as those have different rules
			if WalletConnectService.temp_isUnstake(operations: operations) == nil,
			   WalletConnectService.temp_isFinaliseUnstake(operations: operations) == nil,
			   (xtzSend + operationsObj.fee) > xtzBalance {
				
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
					let baker = TzKTBaker(address: currentDelegate.address, name: currentDelegate.alias ?? currentDelegate.address.truncateTezosAddress())
					TransactionService.shared.delegateData.chosenBaker = baker
				}
				
			} else {
				let baker = TzKTBaker(address: "", name: "")
				TransactionService.shared.delegateData.chosenBaker = baker
			}
			
		} else {
			TransactionService.shared.delegateData.isAdd = true
			let operationAddress = delegateOperation.delegate ?? ""
			
			if let matchingBaker = (bakers ?? []).filter({ $0.address == (operationAddress) }).first {
				TransactionService.shared.delegateData.chosenBaker = matchingBaker
				
			} else {
				let baker = TzKTBaker(address: operationAddress, name: operationAddress.truncateTezosAddress())
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
