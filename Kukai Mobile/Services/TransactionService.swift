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
		case walletConnectOperation
		case none
	}
	
	public enum WalletConnectOperationType {
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
		var operations: [KukaiCoreSwift.Operation]?
		var calculationResult: DexSwapCalculationResult?
		var isXtzToToken: Bool?
		var fromAmount: TokenAmount?
		var toAmount: TokenAmount?
		var exchangeRateString: String?
	}
	
	public struct LiquidityDetails {
		var selectedPosition: DipDupPositionData?
	}
	
	public struct AddLiquidityData {
		var selectedExchangeAndToken: DipDupExchange?
		var operations: [KukaiCoreSwift.Operation]?
		var calculationResult: DexAddCalculationResult?
		var token1: TokenAmount?
		var token2: TokenAmount?
	}
	
	public struct RemoveLiquidityData {
		var position: DipDupPositionData?
		var operations: [KukaiCoreSwift.Operation]?
		var calculationResult: DexRemoveCalculationResult?
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
		var operationType: WalletConnectOperationType?
		var tokenToSend: Token?
		var entrypointToCall: String?
		var beaconRequest: OperationTezosRequest?
	}
	
	public struct WalletConnectOperationData {
		var proposal: Session.Proposal?
		var request: WalletConnectSign.Request?
		var requestParams: WalletConnectRequestParams?
		var operationType: WalletConnectOperationType?
		var estimatedOperations: [KukaiCoreSwift.Operation]?
		var tokenToSend: Token?
		var entrypointToCall: String?
	}
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	public var exchangeData: ExchangeData
	public var liquidityDetails: LiquidityDetails
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	public var beaconApproveData: BeaconApproveData
	public var beaconSignData: BeaconSignData
	public var beaconOperationData: BeaconOperationData
	public var walletConnectOperationData: WalletConnectOperationData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, operations: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, operations: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, operations: nil, calculationResult: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData(estimatedOperations: nil, operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil, estimatedOperations: nil, tokenToSend: nil, entrypointToCall: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, operations: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, operations: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, operations: nil, calculationResult: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData(estimatedOperations: nil, operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil, estimatedOperations: nil, tokenToSend: nil, entrypointToCall: nil)
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
