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
	
	// MARK: - Enums
	
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
	
	public enum FeeType: Int {
		case normal
		case fast
		case custom
		
		func displayName() -> String {
			switch self {
				case .normal:
					return "Normal"
				
				case .fast:
					return "Fast"
				
				case .custom:
					return "Custom"
			}
		}
	}
	
	
	
	// MARK: - Structs
	
	/**
	 Object to store 3 copies of `currentOperations` allowing users to choose which fees they would like to use, or switch back and forth without having to recalculate each time.
	 The instance of this object is automatically set every time `currentOperations` is set.
	 The `type` attribute of this object should be set with the users choice, and then `selectedOperationsAndFees` should be used to inject after the user approves
	 */
	public struct FeeData {
		var type: FeeType
		
		private var normalOperationsAndFees: [KukaiCoreSwift.Operation] = []
		private var fastOperationsAndFees: [KukaiCoreSwift.Operation] = []
		private var customOperationsAndFees: [KukaiCoreSwift.Operation] = []
		
		func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
			switch type {
				case .normal:
					return normalOperationsAndFees
					
				case .fast:
					return fastOperationsAndFees
					
				case .custom:
					return customOperationsAndFees
			}
		}
		
		var gasLimit: Int {
			get { selectedOperationsAndFees().map({ $0.operationFees.gasLimit }).reduce(0, +) }
		}
		
		var storageLimit: Int {
			get { selectedOperationsAndFees().map({ $0.operationFees.storageLimit }).reduce(0, +) }
		}
		
		var fee: XTZAmount {
			get { selectedOperationsAndFees().map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +) }
		}
		
		var maxStorageCost: XTZAmount {
			get { selectedOperationsAndFees().map({ $0.operationFees.allNetworkFees() }).reduce(XTZAmount.zero(), +) }
		}
		
		init(estimatedOperations: [KukaiCoreSwift.Operation]) {
			self.type = .normal
			self.normalOperationsAndFees = FeeData.makeCopyOf(operations: estimatedOperations) ?? []
			self.customOperationsAndFees = FeeData.makeCopyOf(operations: estimatedOperations) ?? []
			
			let operationCopy = FeeData.makeCopyOf(operations: estimatedOperations) ?? []
			let normalTotalFee = operationCopy.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +)
			let normalTotalGas = operationCopy.map({ $0.operationFees.gasLimit }).reduce(0, +)
			let increasedFee = XTZAmount(fromNormalisedAmount: normalTotalFee * Decimal(2))
			let increasedGas = Int(Double(normalTotalGas) * 1.5)
			
			self.fastOperationsAndFees = increase(operations: operationCopy, feesTo: increasedFee, gasLimitTo: increasedGas, storageLimitTo: nil)
		}
		
		/// KukaiCoreSwift.Operation are classes passed by reference. Making changes to them will make changes to every reference. They are small but complex classes with a complex fee structure + business logic.
		/// Use this to create a quick and hacky copy. Chosing this method as the user will be presented with 3 choices for fees. Rahter than calculating, recalculating, reverting etc, on a complex fee structure, KIFS (Keep It Fucking Simple).
		/// Just create 3 static copies and let users switch/view between the ones they want, avoiding excessively complex business logic
		public static func makeCopyOf(operations: [KukaiCoreSwift.Operation]) -> [KukaiCoreSwift.Operation]? {
			guard let opJson = try? JSONEncoder().encode(operations), let opsCopy = try? JSONDecoder().decode([KukaiCoreSwift.Operation].self, from: opJson) else {
				return nil
			}
			
			return opsCopy
		}
		
		func increase(operations: [KukaiCoreSwift.Operation], feesTo: XTZAmount?, gasLimitTo: Int?, storageLimitTo: Int?) -> [KukaiCoreSwift.Operation] {
			var gasPerOp: Decimal? = nil
			if let gasLimitTo = gasLimitTo {
				gasPerOp = (Decimal(gasLimitTo) / Decimal(operations.count)).rounded(scale: 0, roundingMode: .bankers)
			}
			
			var storagePerOp: Decimal? = nil
			if let storageLimitTo = storageLimitTo {
				storagePerOp = (Decimal(storageLimitTo) / Decimal(operations.count)).rounded(scale: 0, roundingMode: .bankers)
			}
			
			for (index, op) in operations.enumerated() {
				
				// Only change on last operation
				if index == operations.count-1, let feesTo = feesTo {
					op.operationFees.transactionFee = feesTo
				}
				
				// Add gas and storage if present
				if let gasPerOp = gasPerOp {
					op.operationFees.gasLimit += NSDecimalNumber(decimal: gasPerOp).intValue
				}
				
				if let storagePerOp = storagePerOp {
					op.operationFees.storageLimit += NSDecimalNumber(decimal: storagePerOp).intValue
				}
			}
			
			return operations
		}
	}
	
	public struct SendData {
		var chosenToken: Token?
		var chosenNFT: NFT?
		var chosenAmount: TokenAmount?
		var destination: String?
		var destinationAlias: String?
		var destinationIcon: UIImage?
	}
	
	public struct ExchangeData {
		var selectedExchangeAndToken: DipDupExchange?
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
		var calculationResult: DexAddCalculationResult?
		var token1: TokenAmount?
		var token2: TokenAmount?
	}
	
	public struct RemoveLiquidityData {
		var position: DipDupPositionData?
		var tokenAmount: TokenAmount?
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
		var tokenToSend: Token?
		var entrypointToCall: String?
	}
	
	
	
	// MARK: - Shared Properties
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType = .none
	public var currentFeeData: FeeData = FeeData(estimatedOperations: [])
	public var currentOperations: [KukaiCoreSwift.Operation] = [] {
		didSet {
			currentFeeData = FeeData(estimatedOperations: currentOperations)
		}
	}
	
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
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData( operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil, tokenToSend: nil, entrypointToCall: nil)
	}
	
	
	
	// MARK: - functions
	
	public func resetState() {
		self.currentTransactionType = .none
		self.currentOperations = []
		
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		self.beaconApproveData = BeaconApproveData(request: nil)
		self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		self.beaconOperationData = BeaconOperationData( operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil, tokenToSend: nil, entrypointToCall: nil)
	}
	
	public func recordChosen(exchange: DipDupExchange) {
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
