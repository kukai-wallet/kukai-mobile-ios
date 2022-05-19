//
//  BeaconService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/08/2021.
//

import UIKit
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos
import BeaconClientWallet
import BeaconTransportP2PMatrix
import Base58Swift
import WalletCore
import os.log

public protocol BeaconServiceConnectionDelegate: AnyObject {
	func permissionRequest(requestingAppName: String, permissionRequest: PermissionTezosRequest)
	func signPayload(requestingAppName: String, humanReadableString: String, payloadRequest: SignPayloadTezosRequest)
}

public protocol BeaconServiceOperationDelegate: AnyObject {
	func operationRequest(requestingAppName: String, operationRequest: OperationTezosRequest)
}

public struct PeerDisplay: Hashable {
	let id: String
	let name: String
	let server: String
	let publicKey: String
}

public struct PermissionDisplay: Hashable {
	let id: String
	let name: String
	let address: String
	let accountIdentifier: String
}

public class BeaconService {
	
	public static let shared = BeaconService()
	public weak var connectionDelegate: BeaconServiceConnectionDelegate?
	public weak var operationDelegate: BeaconServiceOperationDelegate?
	
	private var beaconClient: Beacon.WalletClient?
	
	public func createPeerObjectFromQrCode(_ string: String) -> Beacon.P2PPeer? {
		guard let url = URL(string: string), let params = url.query?.components(separatedBy: "&"), params.count == 2 else {
			os_log("QR code was not a valid beacon payload: %@", log: .default, type: .error, string)
			return nil
		}
		
		if params[0].components(separatedBy: "=").last == "tzip10", let dataString = params[1].components(separatedBy: "=").last {
			
			let dataBytes = Base58.base58CheckDecode(dataString)
			let dataData = Data(bytes: dataBytes ?? [], count: dataBytes?.count ?? 0)
			
			do {
				return try JSONDecoder().decode(Beacon.P2PPeer.self, from: dataData)
				
			} catch (let error) {
				os_log("Beacon parse error: %@", log: .default, type: .error, "\(error)")
			}
			
			return nil
			
		} else {
			os_log("Unsupported tzip standard: %@", log: .default, type: .error, params[0])
			return nil
		}
	}
	
	public func startBeacon(completion: @escaping ((Bool) -> Void)) {
		guard let matrix = try? Transport.P2P.Matrix.connection() else {
			completion(false)
			return
		}
		
		let config = Beacon.WalletClient.Configuration(name: "Kukai iOS", blockchains: [Tezos.factory], connections: [matrix])
		Beacon.WalletClient.create(with: config) { [weak self] result in
			guard let client = try? result.get() else {
				print("Could not create Beacon client, got error: \( String(describing: try? result.getError()) )")
				return
			}
			
			self?.beaconClient = client
			self?.beaconClient?.connect { [weak self] result in
				guard let self = self else {
					completion(false)
					return
				}
				
				self.beaconClient?.listen(onRequest: self.onBeaconRequest)
				completion(true)
			}
		}
	}
	
	public func stopBeacon(completion: @escaping ((Bool) -> Void)) {
		beaconClient?.disconnect(completion: { result in
			guard let _ = try? result.get() else {
				completion(false)
				return
			}
			
			completion(true)
		})
	}
	
	private func onBeaconRequest(result: Result<BeaconRequest<Tezos>, Beacon.Error>) {
		guard let request = try? result.get() else {
			print("Error while processing incoming messages: \( String(describing: try? result.getError()) )")
			return
		}
		
		switch request {
				
			case .permission(let permission):
				DispatchQueue.main.async { [weak self] in
					self?.connectionDelegate?.permissionRequest(requestingAppName: permission.appMetadata.name, permissionRequest: permission)
				}
			
			case .blockchain(let blockchain):
				switch blockchain {
					case .operation(let operation):
						DispatchQueue.main.async { [weak self] in
							self?.operationDelegate?.operationRequest(requestingAppName: operation.appMetadata?.name ?? "", operationRequest: operation)
						}
						
					case .signPayload(let signPayload):
						DispatchQueue.main.async { [weak self] in
							let readableString = self?.convert(hexString: signPayload.payload) ?? ""
							self?.connectionDelegate?.signPayload(requestingAppName: signPayload.appMetadata?.name ?? "", humanReadableString: readableString, payloadRequest: signPayload)
						}
						
					case .broadcast(_):
						break // Braodcast is not used
				}
		}
	}
	
	public func addPeer(_ peer: Beacon.P2PPeer?, completion: @escaping ((Bool) -> Void)) {
		guard let peer = peer else {
			completion(false)
			return
		}
		
		beaconClient?.add([.p2p(peer)], completion: { result in
			switch result {
				case .success():
					completion(true)
					
				case .failure(_):
					completion(false)
			}
		})
	}
	
	public func getPeers(completion: @escaping ((Result<[PeerDisplay], ErrorResponse>) -> Void)) {
		beaconClient?.getPeers(completion: { result in
			guard let res = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			var array: [PeerDisplay] = []
			for (index, obj) in res.enumerated() {
				if case let .p2p(p2p) = obj {
					array.append(PeerDisplay(id: p2p.id ?? "\(index):\(p2p.name)", name: p2p.name, server: p2p.relayServer, publicKey: p2p.publicKey))
				}
			}
			
			completion(Result.success(array))
		})
	}
	
	public func getPermissions(completion: @escaping ((Result<[PermissionDisplay], ErrorResponse>) -> Void)) {
		beaconClient?.getPermissions { (result: Result<[Tezos.Permission], Beacon.Error>) in
			guard let res = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			var array: [PermissionDisplay] = []
			for (index, obj) in res.enumerated() {
				array.append(PermissionDisplay(id: "\(index):\(obj.appMetadata.name)", name: obj.appMetadata.name, address: obj.address, accountIdentifier: obj.accountID))
			}
			
			completion(Result.success(array))
		}
	}
	
	public func removePeer(_ peer: PeerDisplay, completion: @escaping ((Result<(), ErrorResponse>) -> Void)) {
		beaconClient?.removePeer(withPublicKey: peer.publicKey, completion: { result in
			guard let _ = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			completion(Result.success(()))
		})
	}
	
	public func removePermission(_ permission: PermissionDisplay, completion: @escaping ((Result<(), ErrorResponse>) -> Void)) {
		beaconClient?.removePermissions(forAccountIdentifier: permission.accountIdentifier, completion: { result in
			guard let _ = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			completion(Result.success(()))
		})
	}
	
	public func removeAllPeers(completion: @escaping ((Result<(), ErrorResponse>) -> Void)) {
		beaconClient?.removeAllPeers(completion: { result in
			guard let _ = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			completion(Result.success(()))
		})
	}
	
	public func removerAllPermissions(completion: @escaping ((Result<(), ErrorResponse>) -> Void)) {
		beaconClient?.removeAllPermissions(completion: { result in
			guard let _ = try? result.get() else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: (try? result.getError()) ?? .unknown)))
				return
			}
			
			completion(Result.success(()))
		})
	}
	
	
	
	
	
	// MARK: - Completion actions
	
	public func acceptPermissionRequest(permission: PermissionTezosRequest, wallet: KukaiCoreSwift.Wallet, completion: @escaping ((Result<(), ErrorResponse>) -> ())) {
		guard let account = try? Tezos.Account(publicKey: wallet.publicKeyBase58encoded(), address: wallet.address, network: permission.network)  else {
			completion(Result.failure(ErrorResponse.error(string: "Can't create Beacon.Tezos.Account", errorType: .unknownError)))
			return
		}
		
		let response = BeaconResponse<Tezos>.permission(PermissionTezosResponse(from: permission, account: account))
		beaconClient?.respond(with: response, completion: { result in
			switch result {
				case .success():
					DispatchQueue.main.async {
						completion(Result.success(()))
					}
				
				case .failure(let error):
					DispatchQueue.main.async {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
					}
			}
		})
	}
	
	public func rejectPermissionRequest(permission: PermissionTezosRequest, completion: @escaping ((Result<(), ErrorResponse>) -> ())) {
		let response = BeaconResponse<Tezos>.error(ErrorBeaconResponse(from: permission, errorType: .aborted))
		beaconClient?.respond(with: response, completion: { result in
			switch result {
				case .success():
					DispatchQueue.main.async {
						completion(Result.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
					}
			}
		})
	}
	
	public func signPayloadRequest(request: SignPayloadTezosRequest, signature: String, completion: @escaping ((Result<(), ErrorResponse>) -> ())) {
		let obj = SignPayloadTezosResponse(from: request, signature: signature)
		let response = BeaconResponse<Tezos>.blockchain(.signPayload(obj))
		
		beaconClient?.respond(with: response, completion: { result in
			switch result {
				case .success():
					DispatchQueue.main.async {
						completion(Result.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
					}
			}
		})
	}
	
	public func approveOperationRequest(operation: OperationTezosRequest, opHash: String, completion: @escaping ((Result<(), ErrorResponse>) -> ())) {
		let response = BeaconResponse<Tezos>.blockchain(.operation(OperationTezosResponse(from: operation, transactionHash: opHash)))
		beaconClient?.respond(with: response, completion: { result in
			switch result {
				case .success():
					DispatchQueue.main.async {
						completion(Result.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
					}
			}
		})
	}
	
	public func rejectRequest(request: Tezos.Request.Blockchain, completion: @escaping ((Result<(), ErrorResponse>) -> ())) {
		let response = BeaconResponse<Tezos>.error(ErrorBeaconResponse(from: request, errorType: .aborted))
		beaconClient?.respond(with: response, completion: { result in
			switch result {
				case .success():
					DispatchQueue.main.async {
						completion(Result.success(()))
					}
					
				case .failure(let error):
					DispatchQueue.main.async {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
					}
			}
		})
	}
	
	
	
	
	
	// MARK: - Helpers and parsers
	
	public static func process(operation: OperationTezosRequest, forWallet wallet: KukaiCoreSwift.Wallet) -> [KukaiCoreSwift.Operation] {
		var ops: [KukaiCoreSwift.Operation] = []
		
		for op in operation.operationDetails {
			
			// Extract Beacon Operation JSON as Data
			guard let opJson = try? JSONEncoder().encode(op) else {
				continue
			}
			
			// Convert Beacon Type into Kukai type, so that we can run our own estimation and injection logic
			var convertedOp: KukaiCoreSwift.Operation? = nil
			switch op {
				case .activateAccount(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationActivateAccount.self, forWallet: wallet)
				case .ballot(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationBallot.self, forWallet: wallet)
				case .delegation(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationDelegation.self, forWallet: wallet)
				case .doubleBakingEvidence(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationDoubleBakingEvidence.self, forWallet: wallet)
				case .doubleEndorsementEvidence(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationDoubleEndorsementEvidence.self, forWallet: wallet)
				case .endorsement(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationEndorsement.self, forWallet: wallet)
				case .origination(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationOrigination.self, forWallet: wallet)
				case .proposals(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationProposals.self, forWallet: wallet)
				case .reveal(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationReveal.self, forWallet: wallet)
				case .seedNonceRevelation(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationSeedNonceRevelation.self, forWallet: wallet)
				case .transaction(_):
					convertedOp = convert(beaconOp: opJson, toKukaiOpType: OperationTransaction.self, forWallet: wallet)
			}
			
			// If it worked, add to array
			if let kukaiOp = convertedOp {
				ops.append(kukaiOp)
			}
		}
		
		return ops
	}
	
	public static func convert(beaconOp: Data, toKukaiOpType kukaiType: KukaiCoreSwift.Operation.Type, forWallet wallet: KukaiCoreSwift.Wallet) -> KukaiCoreSwift.Operation? {
		do {
			let convertedOp = try JSONDecoder().decode(kukaiType.self, from: beaconOp)
			convertedOp.source = wallet.address
			return convertedOp
			
		} catch (let error) {
			os_log("Failed to parse BeaconOperation into KukaiOperation: %@", log: .default, type: .error, "\(error)")
		}
		
		return nil
	}
	
	public func convert(hexString: String) -> String {
		if String(hexString.prefix(6)) == "050100" {
			let index = hexString.index(hexString.startIndex, offsetBy: 10)
			let subString = String(hexString.suffix(from: index))
			
			let d = Data(hexString: subString) ?? Data()
			let readable = String(data: d, encoding: .isoLatin1)
			
			return readable ?? ""
		}
		
		let d = Data(hexString: hexString) ?? Data()
		let readable = String(data: d, encoding: .isoLatin1)
		
		return readable ?? ""
	}
}
