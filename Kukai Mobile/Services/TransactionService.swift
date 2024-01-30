//
//  TransactionService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import Foundation
import KukaiCoreSwift
import WalletConnectSign
import UIKit
import OSLog

public class TransactionService {
	
	// MARK: - Enums
	
	public enum TransactionType {
		case send
		case delegate
		case exchange
		case addLiquidity
		case removeLiquidity
		case contractCall
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
	
	public enum WalletIconSize: Int {
		case size_12 = 12
		case size_16 = 16
		case size_20 = 20
		case size_22 = 22
		case size_24 = 24
		case size_26 = 26
		case size_30 = 30
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
			self.normalOperationsAndFees = estimatedOperations.copyOperations()
			self.customOperationsAndFees = estimatedOperations.copyOperations()
			
			let operationCopy = estimatedOperations.copyOperations()
			let normalTotalFee = operationCopy.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +)
			let normalTotalGas = operationCopy.map({ $0.operationFees.gasLimit }).reduce(0, +)
			let increasedFee = XTZAmount(fromNormalisedAmount: normalTotalFee * Decimal(2))
			let increasedGas = (Decimal(normalTotalGas) * 1.5).intValue()
			
			self.fastOperationsAndFees = increase(operations: operationCopy, feesTo: increasedFee, gasLimitTo: increasedGas, storageLimitTo: nil)
		}
		
		/// When trying to send max XTZ, we need to work out the fee first and subtract. Afterwards we need to update the sotred operations
		public func updateXTZAmount(to newAmount: TokenAmount) {
			(normalOperationsAndFees.last as? OperationTransaction)?.amount = newAmount.rpcRepresentation
			(fastOperationsAndFees.last as? OperationTransaction)?.amount = newAmount.rpcRepresentation
			(customOperationsAndFees.last as? OperationTransaction)?.amount = newAmount.rpcRepresentation
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
			
			if let constants = DependencyManager.shared.tezosNodeClient.networkConstants {
				let totalStorage = operations.map({ $0.operationFees.storageLimit }).reduce(0, +)
				let newBurnFee = FeeEstimatorService.feeForBurn(totalStorage, withConstants: constants)
				operations.last?.operationFees.networkFees[OperationFees.NetworkFeeType.burnFee] = newBurnFee
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
	
	public struct DelegateData {
		var chosenBaker: TzKTBaker?
		var isAdd: Bool?
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
	
	public struct BatchData {
		var operationCount: Int?
		var selectedOp: Int?
		var opSummaries: [BatchOpSummary]?
	}
	
	public struct BatchOpSummary {
		var chosenToken: Token?
		var chosenAmount: TokenAmount?
		var contractAddress: String?
		var operationCount: Int?
		var mainEntrypoint: String?
	}
	
	public struct WalletConnectOperationData {
		var currentTransactionType: TransactionType
		var proposal: Session.Proposal?
		var request: WalletConnectSign.Request?
		var requestParams: WalletConnectRequestParams?
		
		var sendData: SendData
		var batchData: BatchData
	}
	
	
	
	// MARK: - Shared Properties
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType = .none
	public var currentOperationsAndFeesData: OperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
	public var currentForgedString = ""
	public var currentRemoteOperationsAndFeesData: OperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
	public var currentRemoteForgedString = ""
	
	public var sendData: SendData
	public var delegateData: DelegateData
	public var exchangeData: ExchangeData
	public var liquidityDetails: LiquidityDetails
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	public var batchData: BatchData
	public var walletConnectOperationData: WalletConnectOperationData
	
	
	private init() {
		self.currentTransactionType = .none
		self.currentOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		self.currentRemoteOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.delegateData = DelegateData(chosenBaker: nil, isAdd: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		self.batchData = BatchData(operationCount: nil, selectedOp: nil, opSummaries: nil)
		self.walletConnectOperationData = WalletConnectOperationData(currentTransactionType: .none,
																	 proposal: nil,
																	 request: nil,
																	 requestParams: nil,
																	 sendData: SendData(chosenToken: nil,
																						chosenNFT: nil,
																						chosenAmount: nil,
																						destination: nil,
																						destinationAlias: nil,
																						destinationIcon: nil),
																	 batchData: BatchData(operationCount: nil,
																						  selectedOp: nil,
																						  opSummaries: nil)
		)
	}
	
	
	
	// MARK: - functions
	
	public func resetAllState() {
		self.currentTransactionType = .none
		self.currentOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		self.currentForgedString = ""
		self.currentRemoteOperationsAndFeesData = OperationsAndFeesData(estimatedOperations: [])
		self.currentRemoteForgedString = ""
		
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil)
		self.delegateData = DelegateData(chosenBaker: nil, isAdd: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil, calculationResult: nil, isXtzToToken: nil, fromAmount: nil, toAmount: nil, exchangeRateString: nil)
		self.liquidityDetails = LiquidityDetails(selectedPosition: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil, calculationResult: nil, token1: nil, token2: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil, tokenAmount: nil, calculationResult: nil)
		self.batchData = BatchData(operationCount: nil, selectedOp: nil, opSummaries: nil)
		
		self.resetWalletConnectState()
	}
	
	public func resetWalletConnectState() {
		self.walletConnectOperationData = WalletConnectOperationData(currentTransactionType: .none,
																	 proposal: nil,
																	 request: nil,
																	 requestParams: nil,
																	 sendData: SendData(chosenToken: nil,
																						chosenNFT: nil,
																						chosenAmount: nil,
																						destination: nil,
																						destinationAlias: nil,
																						destinationIcon: nil),
																	 batchData: BatchData(operationCount: nil, 
																						  selectedOp: nil,
																						  opSummaries: nil))
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
		let imageSize = TransactionService.sizeForWalletIcon(walletIconSize: size)
		let currentNetwork = DependencyManager.shared.currentNetworkType
		
		if metadata.type != .social {
			let image = UIImage(named: "Social_TZ_1color")?.resizedImage(size: imageSize)?.withTintColor(.colorNamed("BGB4")) ?? UIImage()
			var title = ""
			var subtitle: String? = ""
			
			if  let nickname = metadata.walletNickname {
				
				// If non social, check for nicknames first
				title = nickname
				subtitle =  metadata.address.truncateTezosAddress()
				
			} else if metadata.hasDomain(onNetwork: currentNetwork) {
				
				// If no nicknames, check for tezos domains
				let image = UIImage(named: "Social_TZDomain_Color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.primaryDomain(onNetwork: currentNetwork)?.domain.name ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			} else {
				
				// Use address
				title =  metadata.address.truncateTezosAddress()
				subtitle = nil
			}
			
			return (image: image, title: title, subtitle: subtitle)
		}
		
		// Iterate through social
		switch metadata.socialType {
			case .apple:
				let image = UIImage(named: "Social_Apple")?.resizedImage(size: imageSize)?.withTintColor(.colorNamed("Txt2")) ?? UIImage()
				return (image: image, title: "Apple account", subtitle: metadata.address.truncateTezosAddress())
				
			case .twitter:
				let image = UIImage(named: "Social_Twitter_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? metadata.socialUserId ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .google:
				let image = UIImage(named: "Social_Google_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUserId ?? metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .reddit:
				let image = UIImage(named: "Social_Reddit_Color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .facebook:
				let image = UIImage(named: "Social_Facebook_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .discord:
				let image = UIImage(named: "Social_Discord_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .twitch:
				let image = UIImage(named: "Social_Twitch_color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .line:
				let image = UIImage(named: "Social_LineColor")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .github:
				let image = UIImage(named: "Social_Github_Color")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .email:
				let image = UIImage(named: "Social_Email_Outlined")?.resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.socialUsername ?? "", subtitle: metadata.address.truncateTezosAddress())
				
			case .none:
				let image = UIImage.unknownToken().resizedImage(size: imageSize) ?? UIImage()
				return (image: image, title: metadata.address.truncateTezosAddress(), subtitle: nil)
		}
	}
	
	public static func sizeForWalletIcon(walletIconSize: WalletIconSize) -> CGSize {
		let raw = walletIconSize.rawValue
		return CGSize(width: raw, height: raw)
	}
}
