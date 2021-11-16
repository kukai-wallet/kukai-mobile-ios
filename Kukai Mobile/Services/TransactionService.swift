//
//  TransactionService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import Foundation
import KukaiCoreSwift

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
		var chosenAmount: TokenAmount?
		var destiantion: String?
		var operations: [KukaiCoreSwift.Operation]?
		var ledgerPrep: OperationService.LedgerPayloadPrepResponse?
	}
	
	public struct ExchangeData {
		var selectedPair: TezToolPair?
		var selectedPrice: TezToolPrice?
	}
	
	public struct AddLiquidityData {
		var selectedPair: TezToolPair?
		var selectedPrice: TezToolPrice?
	}
	
	public struct RemoveLiquidityData {
		var selectedPair: TezToolPair?
		var selectedPrice: TezToolPrice?
	}
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	public var exchangeData: ExchangeData
	public var addLiquidityData: AddLiquidityData
	public var removeLiquidityData: RemoveLiquidityData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedPair: nil, selectedPrice: nil)
		self.addLiquidityData = AddLiquidityData(selectedPair: nil, selectedPrice: nil)
		self.removeLiquidityData = RemoveLiquidityData(selectedPair: nil, selectedPrice: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedPair: nil, selectedPrice: nil)
		self.addLiquidityData = AddLiquidityData(selectedPair: nil, selectedPrice: nil)
		self.removeLiquidityData = RemoveLiquidityData(selectedPair: nil, selectedPrice: nil)
	}
	
	public func record(pair: TezToolPair, price: TezToolPrice) {
		switch self.currentTransactionType {
			case .exchange:
				self.exchangeData.selectedPair = pair
				self.exchangeData.selectedPrice = price
				
			case .addLiquidity:
				self.addLiquidityData.selectedPair = pair
				self.addLiquidityData.selectedPrice = price
				
			case .removeLiquidity:
				self.removeLiquidityData.selectedPair = pair
				self.removeLiquidityData.selectedPrice = price
			
			default:
				break
		}
	}
}
