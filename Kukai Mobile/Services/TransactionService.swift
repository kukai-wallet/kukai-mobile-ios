//
//  TransactionService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import Foundation
import KukaiCoreSwift
//import BeaconCore
//import BeaconBlockchainTezos
import WalletConnectSign
import UIKit
import OSLog

public class TransactionService {
	
	// MARK: - Enums
	
	public enum TransactionType {
		case send
		case exchange
		case addLiquidity
		case removeLiquidity
		//case beaconApprove
		//case beaconSign
		//case beaconOperation
		case none
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
	
	public enum WalletIconSize {
		case small
		case medium
		case large
	}
	
	
	
	// MARK: - Structs
	
	/**
	 Object to store 3 copies of `currentOperations` allowing users to choose which fees they would like to use, or switch back and forth without having to recalculate each time.
	 The instance of this object is automatically set every time `currentOperations` is set.
	 The `type` attribute of this object should be set with the users choice, and then `selectedOperationsAndFees` should be used to inject after the user approves
	 */
	public struct OperationsAndFeesData {
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
		
		public init(estimatedOperations: [KukaiCoreSwift.Operation]) {
			self.type = .normal
			self.normalOperationsAndFees = TransactionService.makeCopyOf(operations: estimatedOperations)
			self.customOperationsAndFees = TransactionService.makeCopyOf(operations: estimatedOperations)
			
			let operationCopy = TransactionService.makeCopyOf(operations: estimatedOperations)
			let normalTotalFee = operationCopy.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +)
			let normalTotalGas = operationCopy.map({ $0.operationFees.gasLimit }).reduce(0, +)
			let increasedFee = XTZAmount(fromNormalisedAmount: normalTotalFee * Decimal(2))
			let increasedGas = (Decimal(normalTotalGas) * 1.5).intValue()
			
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
		
		public mutating func setCustomFeesTo(feesTo: XTZAmount?, gasLimitTo: Int?, storageLimitTo: Int?) {
			customOperationsAndFees = increase(operations: self.customOperationsAndFees, feesTo: feesTo, gasLimitTo: gasLimitTo, storageLimitTo: storageLimitTo)
		}
		
		func increase(operations: [KukaiCoreSwift.Operation], feesTo: XTZAmount?, gasLimitTo: Int?, storageLimitTo: Int?) -> [KukaiCoreSwift.Operation] {
			var gasPerOp: Int? = nil
			if let gasLimitTo = gasLimitTo {
				let totalCurrentGas = operations.map({ $0.operationFees.gasLimit }).reduce(0, +)
				let difference = gasLimitTo - totalCurrentGas
				
				gasPerOp = (Decimal(difference) / Decimal(operations.count)).intValue()
			}
			
			var storagePerOp: Int? = nil
			if let storageLimitTo = storageLimitTo {
				let totalCurrentStorage = operations.map({ $0.operationFees.storageLimit }).reduce(0, +)
				let difference = storageLimitTo - totalCurrentStorage
				
				storagePerOp = (Decimal(difference) / Decimal(operations.count)).intValue()
			}
			
			
			for (index, op) in operations.enumerated() {
				
				// Only change on last operation
				if index == operations.count-1, let feesTo = feesTo {
					op.operationFees.transactionFee = feesTo
				}
				
				// Add gas and storage if present
				if let gasPerOp = gasPerOp {
					op.operationFees.gasLimit += gasPerOp
				}
				
				if let storagePerOp = storagePerOp {
					op.operationFees.storageLimit += storagePerOp
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
	
	/*
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
	*/
	public struct WalletConnectOperationData {
		var proposal: Session.Proposal?
		var request: WalletConnectSign.Request?
		var requestParams: WalletConnectRequestParams?
	}
	
	
	
	// MARK: - Shared Properties
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType = .none
	public var currentOperationsAndFeesData: OperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
	
	public var sendData: SendData
	public var exchangeData: ExchangeData
	public var liquidityDetails: LiquidityDetails
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	//public var beaconApproveData: BeaconApproveData
	//public var beaconSignData: BeaconSignData
	//public var beaconOperationData: BeaconOperationData
	public var walletConnectOperationData: WalletConnectOperationData
	
	
	private init() {
		self.currentTransactionType = .none
		self.currentOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		//self.beaconApproveData = BeaconApproveData(request: nil)
		//self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		//self.beaconOperationData = BeaconOperationData( operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil)
	}
	
	
	
	// MARK: - functions
	
	public func resetState() {
		self.currentTransactionType = .none
		self.currentOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		//self.beaconApproveData = BeaconApproveData(request: nil)
		//self.beaconSignData = BeaconSignData(request: nil, humanReadableString: nil)
		//self.beaconOperationData = BeaconOperationData( operationType: nil, tokenToSend: nil, entrypointToCall: nil, beaconRequest: nil)
		self.walletConnectOperationData = WalletConnectOperationData(proposal: nil, request: nil, requestParams: nil)
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
	
	public static func walletMedia(forWalletMetadata metadata: WalletMetadata, ofSize size: WalletIconSize) -> (image: UIImage, title: String, subtitle: String?) {
		
		// Early exit if tezos domain
		if metadata.hasTezosDomain() {
			var imageSize = CGSize(width: 10, height: 10)
			switch size {
				case .small:
					imageSize = CGSize(width: 16, height: 16)
				case .medium:
					imageSize = CGSize(width: 21, height: 21)
				case .large:
					imageSize = CGSize(width: 24, height: 24)
			}
			
			let image = UIImage(named: "Social_TZDomain_Color")?.resizedImage(size: imageSize) ?? UIImage()
			return (image: image, title: metadata.tezosDomain ?? "", subtitle: metadata.address.truncateTezosAddress())
		}
		
		// Second Early exit if non-social wallet without domain
		if metadata.type != .social {
			var imageSize = CGSize(width: 10, height: 10)
			switch size {
				case .small:
					imageSize = CGSize(width: 10, height: 14)
				case .medium:
					imageSize = CGSize(width: 14, height: 18)
				case .large:
					imageSize = CGSize(width: 17, height: 23)
			}
			
			let image = UIImage(named: "Social_TZ_1color")?.resizedImage(size: imageSize)?.withTintColor(.colorNamed("BGB4")) ?? UIImage()
			return (image: image, title: metadata.address.truncateTezosAddress(), subtitle: nil)
		}
		
		// Iterate through social
		switch metadata.socialType {
			case .apple:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 14, height: 14)
					case .medium:
						imageSize = CGSize(width: 18, height: 18)
					case .large:
						imageSize = CGSize(width: 23, height: 23)
				}
				
				let image = UIImage(named: "Social_Apple")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: "Apple account", subtitle: metadata.address.truncateTezosAddress())
				
			case .twitter:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 16, height: 12)
					case .medium:
						imageSize = CGSize(width: 18, height: 14)
					case .large:
						imageSize = CGSize(width: 21, height: 16)
				}
				
				let image = UIImage(named: "Social_Twitter_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.displayName ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .google:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 14, height: 14)
					case .medium:
						imageSize = CGSize(width: 18, height: 18)
					case .large:
						imageSize = CGSize(width: 23, height: 23)
				}
				
				let image = UIImage(named: "Social_Google_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.displayName ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .reddit:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 16, height: 16)
					case .medium:
						imageSize = CGSize(width: 21, height: 21)
					case .large:
						imageSize = CGSize(width: 23, height: 23)
				}
				
				let image = UIImage(named: "Social_Reddit_Color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.displayName ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .facebook:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 16, height: 16)
					case .medium:
						imageSize = CGSize(width: 21, height: 21)
					case .large:
						imageSize = CGSize(width: 23, height: 23)
				}
				
				let image = UIImage(named: "Social_Facebook_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.displayName ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .none:
				var imageSize = CGSize(width: 10, height: 10)
				switch size {
					case .small:
						imageSize = CGSize(width: 16, height: 16)
					case .medium:
						imageSize = CGSize(width: 21, height: 21)
					case .large:
						imageSize = CGSize(width: 23, height: 23)
				}
				
				let image = UIImage.unknownToken().resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.address.truncateTezosAddress(), subtitle: nil)
		}
	}
	
	
	/// Hacky function to create a deep copy of an array of Operations
	public static func makeCopyOf(operations: [KukaiCoreSwift.Operation]) -> [KukaiCoreSwift.Operation] {
		guard let opJson = try? JSONEncoder().encode(operations), let jsonArray = try? JSONSerialization.jsonObject(with: opJson, options: .allowFragments) as? [[String: Any]] else {
			return []
		}
		
		var ops: [KukaiCoreSwift.Operation] = []
		for jsonObj in jsonArray {
			guard let kind = OperationKind(rawValue: (jsonObj["kind"] as? String) ?? ""), let jsonObjAsData = try? JSONSerialization.data(withJSONObject: jsonObj, options: .fragmentsAllowed) else {
				os_log("Unable to parse operation of kind: %@", log: .default, type: .error, (jsonObj["kind"] as? String) ?? "")
				continue
			}
			
			var tempOp: KukaiCoreSwift.Operation? = nil
			switch kind {
				case .activate_account:
					tempOp = try? JSONDecoder().decode(OperationActivateAccount.self, from: jsonObjAsData)
				case .ballot:
					tempOp = try? JSONDecoder().decode(OperationBallot.self, from: jsonObjAsData)
				case .delegation:
					tempOp = try? JSONDecoder().decode(OperationDelegation.self, from: jsonObjAsData)
				case .double_baking_evidence:
					tempOp = try? JSONDecoder().decode(OperationDoubleBakingEvidence.self, from: jsonObjAsData)
				case .double_endorsement_evidence:
					tempOp = try? JSONDecoder().decode(OperationDoubleEndorsementEvidence.self, from: jsonObjAsData)
				case .endorsement:
					tempOp = try? JSONDecoder().decode(OperationEndorsement.self, from: jsonObjAsData)
				case .origination:
					tempOp = try? JSONDecoder().decode(OperationOrigination.self, from: jsonObjAsData)
				case .proposals:
					tempOp = try? JSONDecoder().decode(OperationProposals.self, from: jsonObjAsData)
				case .reveal:
					tempOp = try? JSONDecoder().decode(OperationReveal.self, from: jsonObjAsData)
				case .seed_nonce_revelation:
					tempOp = try? JSONDecoder().decode(OperationSeedNonceRevelation.self, from: jsonObjAsData)
				case .transaction:
					tempOp = try? JSONDecoder().decode(OperationTransaction.self, from: jsonObjAsData)
				case .unknown:
					tempOp = nil
			}
			
			if let tempOp = tempOp {
				ops.append(tempOp)
			} else {
				os_log("Unable to parse operation: %@", log: .default, type: .error, String(data: jsonObjAsData, encoding: .utf8) ?? "")
			}
		}
		
		return ops
	}
}
