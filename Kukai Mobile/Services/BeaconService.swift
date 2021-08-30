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
	
	
	
	
	
	
	public static func processOperation(operation: Beacon.Request.Operation, forWallet wallet: Wallet) -> [KukaiCoreSwift.Operation] {
		var ops: [KukaiCoreSwift.Operation] = []
		
		for op in operation.operationDetails {
			guard let opJson = try? JSONEncoder().encode(op) else {
				continue
			}
			
			switch op {
				case .transaction(let transaction):
					if transaction.parameters != nil {
						
						do {
							let convertedOp = try JSONDecoder().decode(OperationSmartContractInvocation.self, from: opJson)
							convertedOp.source = wallet.address
							ops.append(convertedOp)
							
						} catch (let error) {
							print("Parsing error: \(error)")
						}
						
						
					} else if let convertedOp = try? JSONDecoder().decode(OperationTransaction.self, from: opJson) {
						convertedOp.source = wallet.address
						ops.append(convertedOp)
						
					} else {
						print("Error - processOperation: of type transaction, but doesn't match OperationTransaction")
					}
				
				default:
					print("Error")
			}
		}
		
		return ops
	}
}
