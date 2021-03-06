//
//  BeaconService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/08/2021.
//

import UIKit
import KukaiCoreSwift
import BeaconSDK
import Base58Swift
import os.log

public protocol BeaconServiceConnectionDelegate: AnyObject {
	func permissionRequest(requestingAppName: String, permissionRequest: Beacon.Request.Permission)
}

public protocol BeaconServiceOperationDelegate: AnyObject {
	func operationRequest(requestingAppName: String, operationRequest: Beacon.Request.Operation)
}

public class BeaconService {
	
	public static let shared = BeaconService()
	public weak var connectionDelegate: BeaconServiceConnectionDelegate?
	public weak var operationDelegate: BeaconServiceOperationDelegate?
	
	private var beaconClient: Beacon.Client?
	
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
		Beacon.Client.create(with: Beacon.Client.Configuration(name: "Kukai Mobile")) { [weak self] result in
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
	
	private func onBeaconRequest(result: Result<Beacon.Request, Beacon.Error>) {
		guard let request = try? result.get() else {
			print("Error while processing incoming messages: \( String(describing: try? result.getError()) )")
			return
		}
		
		switch request {
			case .permission(let permission):
				connectionDelegate?.permissionRequest(requestingAppName: permission.appMetadata.name, permissionRequest: permission)
			
			case .operation(let operation):
				operationDelegate?.operationRequest(requestingAppName: operation.appMetadata?.name ?? "", operationRequest: operation)
				
			case .signPayload(let signPayload):
				print("signPayload: \(signPayload)")
				
			default:
				print("Unsupported request type: \(request)")
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
	
	
	
	// MARK: - Completion actions
	
	public func acceptPermissionRequest(permission: Beacon.Request.Permission, wallet: Wallet, completion: @escaping ((Result<(), Beacon.Error>) -> ())) {
		let response = Beacon.Response.Permission(from: permission, publicKey: wallet.publicKeyBase58encoded())
		beaconClient?.respond(with: .permission(response), completion: completion)
	}
	
	public func rejectPermissionRequest(permission: Beacon.Request.Permission, wallet: Wallet, completion: @escaping ((Result<(), Beacon.Error>) -> ())) {
		let response = Beacon.Response.Error(id: permission.id, errorType: .aborted, version: "2", requestOrigin: permission.origin)
		beaconClient?.respond(with: .error(response), completion: completion)
	}
	
	public func approveOperationRequest(operation: Beacon.Request.Operation, opHash: String, completion: @escaping ((Result<(), Beacon.Error>) -> ())) {
		let response = Beacon.Response.Operation(from: operation, transactionHash: opHash)
		beaconClient?.respond(with: .operation(response), completion: completion)
	}
	
	
	
	// MARK: - Helpers and parsers
	
	public static func process(operation: Beacon.Request.Operation, forWallet wallet: Wallet) -> [KukaiCoreSwift.Operation] {
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
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationActivateAccount.self, forWallet: wallet)
				case .ballot(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationBallot.self, forWallet: wallet)
				case .delegation(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationDelegation.self, forWallet: wallet)
				case .doubleBakingEvidence(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationDoubleBakingEvidence.self, forWallet: wallet)
				case .doubleEndorsementEvidence(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationDoubleEndorsementEvidence.self, forWallet: wallet)
				case .endorsement(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationEndorsement.self, forWallet: wallet)
				case .origination(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationOrigination.self, forWallet: wallet)
				case .proposals(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationProposals.self, forWallet: wallet)
				case .reveal(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationReveal.self, forWallet: wallet)
				case .seedNonceRevelation(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationSeedNonceRevelation.self, forWallet: wallet)
				case .transaction(_):
					convertedOp = convert(beaconOp: opJson, toKukaioOpType: OperationTransaction.self, forWallet: wallet)
			}
			
			// If it worked, add to array
			if let kukaiOp = convertedOp {
				ops.append(kukaiOp)
			}
		}
		
		return ops
	}
	
	public static func convert(beaconOp: Data, toKukaioOpType kukaiType: KukaiCoreSwift.Operation.Type, forWallet wallet: Wallet) -> KukaiCoreSwift.Operation? {
		do {
			let convertedOp = try JSONDecoder().decode(kukaiType.self, from: beaconOp)
			convertedOp.source = wallet.address
			return convertedOp
			
		} catch (let error) {
			os_log("Failed to parse BeaconOperation into KukaiOperation: %@", log: .default, type: .error, "\(error)")
		}
		
		return nil
	}
}
