//
//  TransactionService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import Foundation
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos
import WalletConnectSign
import UIKit

public class TransactionService {
	
	public enum TransactionType {
		case send
		case exchange
		case addLiquidity
		case removeLiquidity
		case beaconApprove
		case beaconSign
		case beaconOperation
		case none
	}
	
	public enum BeaconOperationType {
		case sendXTZ
		case sendToken
		case sendNFT
		case callSmartContract
		case unknown
	}
	
	public struct SendData {
		var chosenToken: Token?
		var chosenNFT: NFT?
		var chosenAmount: TokenAmount?
		var destination: String?
		var destinationAlias: String?
		var destinationIcon: UIImage?
		var operations: [KukaiCoreSwift.Operation]?
		var ledgerPrep: OperationService.LedgerPayloadPrepResponse?
	}
	
	public struct ExchangeData {
		var selectedExchangeAndToken: DipDupExchange?
	}
	
	public struct AddLiquidityData {
		var selectedExchangeAndToken: DipDupExchange?
	}
	
	public struct RemoveLiquidityData {
		var position: DipDupPositionData?
	}
	
	public struct BeaconApproveData {
		var request: PermissionTezosRequest?
	}
	
	public struct BeaconSignData {
		var request: SignPayloadTezosRequest?
		var humanReadableString: String?
	}
	
	public struct BeaconOperationData {
		var estimatedOperations: [KukaiCoreSwift.Operation]?
		var operationType: BeaconOperationType?
		var tokenToSend: Token?
		var entrypointToCall: String?
		var beaconRequest: OperationTezosRequest?
	}
	
	public struct WalletConnectOperationData {
		var proposal: Session.Proposal?
	}
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	public var exchangeData: ExchangeData
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	public var beaconApproveData: BeaconApproveData
	public var beaconSignData: BeaconSignData
	public var beaconOperationData: BeaconOperationData
	public var walletConnectOperationData: WalletConnectOperationData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData(estimatedOperations: nil, operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData(estimatedOperations: nil, operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil)
	}
	
	public func record(exchange: DipDupExchange) {
		switch self.currentTransactionType {
			case .exchange:
				self.exchangeData.selectedExchangeAndToken = exchange
				
			case .addLiquidity:
				self.addLiquidityData.selectedExchangeAndToken = exchange
			
			default:
				break
		}
	}
}
