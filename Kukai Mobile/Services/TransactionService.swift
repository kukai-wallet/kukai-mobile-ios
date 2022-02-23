//
//  TransactionService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import Foundation
import KukaiCoreSwift
import UIKit

public class TransactionService {
	
	public enum TransactionType {
		case send
		case exchange
		case addLiquidity
		case removeLiquidity
		case none
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
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	public var exchangeData: ExchangeData
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenNFT: nil, chosenAmount: nil, destination: nil, destinationAlias: nil, destinationIcon: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedExchangeAndToken: nil)
		self.addLiquidityData = AddLiquidityData(selectedExchangeAndToken: nil)
		self.removeLiquidityData = RemoveLiquidityData(position: nil)
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
