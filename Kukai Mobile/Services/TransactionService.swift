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
		case none
	}
	
	public struct SendData {
		var chosenToken: Token?
		var chosenAmount: TokenAmount?
		var destiantion: String?
		var operations: [KukaiCoreSwift.Operation]?
		var ledgerPrep: OperationService.LedgerPayloadPrepResponse?
	}
	
	
	
	public static let shared = TransactionService()
	
	public var currentTransactionType: TransactionType
	public var sendData: SendData
	
	
	
	private init() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
	}
	
	
	
	public func resetState() {
		self.currentTransactionType = .none
		self.sendData = SendData(chosenToken: nil, chosenAmount: nil, destiantion: nil, operations: nil, ledgerPrep: nil)
	}
}
