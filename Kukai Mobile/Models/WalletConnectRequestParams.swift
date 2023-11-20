//
//  WalletConnectRequestParams.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/07/2022.
//

import Foundation
import KukaiCoreSwift
import WalletConnectSign
import Commons
import OSLog

struct WalletConnectRequestParams: Codable {
	
	let account: String
	let operations: [[String: AnyCodable]]
	
	func kukaiOperations() -> [KukaiCoreSwift.Operation] {
		var parsedOps: [KukaiCoreSwift.Operation] = []
		
		for dict in operations {
			
			// Extract Wallet Connect Operation JSON as Data
			guard let opJson = try? JSONEncoder().encode(dict), let kind = dict["kind"]?.value as? String else {
				continue
			}
			
			var convertedOp: KukaiCoreSwift.Operation? = nil
			switch kind {
				case "endorsement":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationEndorsement.self, forAccount: account)
				case "seed_nonce_revelation":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationSeedNonceRevelation.self, forAccount: account)
				case "double_endorsement_evidence":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationDoubleEndorsementEvidence.self, forAccount: account)
				case "double_baking_evidence":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationDoubleBakingEvidence.self, forAccount: account)
				case "activate_account":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationActivateAccount.self, forAccount: account)
				case "proposals":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationProposals.self, forAccount: account)
				case "ballot":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationBallot.self, forAccount: account)
				case "reveal":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationReveal.self, forAccount: account)
				case "transaction":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationTransaction.self, forAccount: account)
				case "origination":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationOrigination.self, forAccount: account)
				case "delegation":
					convertedOp = WalletConnectRequestParams.convert(json: opJson, toKukaiOpType: OperationDelegation.self, forAccount: account)
				default:
					convertedOp = nil
			}
			
			// If it worked, add to array
			if let kukaiOp = convertedOp {
				parsedOps.append(kukaiOp)
			}
		}
		
		return parsedOps
	}
	
	static func convert(json: Data, toKukaiOpType kukaiType: KukaiCoreSwift.Operation.Type, forAccount account: String) -> KukaiCoreSwift.Operation? {
		do {
			let convertedOp = try JSONDecoder().decode(kukaiType.self, from: json)
			convertedOp.source = account
			return convertedOp
			
		} catch (let error) {
			Logger.app.error("Failed to parse WalletConnectOperation into KukaiOperation: \(error)")
		}
		
		return nil
	}
}
