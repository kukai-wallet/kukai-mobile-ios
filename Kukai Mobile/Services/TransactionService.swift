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
		var selectedPairDecimals: Int?
	}
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	public var exchangeData: ExchangeData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedPair: nil, selectedPairDecimals: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
		self.exchangeData = ExchangeData(selectedPair: nil, selectedPairDecimals: nil)
	}
}
