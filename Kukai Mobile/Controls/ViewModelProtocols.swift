//
//  ViewModel.swift
//  MagmaWallet
//
//  Created by Simon Mcloughlin on 09/01/2020.
//  Copyright © 2020 camlCase Inc. All rights reserved.
//

import UIKit
import Combine
import KukaiCoreSwift

public enum ViewModelError: Error {
	case dataSourceNotCreated
}

public class ViewModel: ObservableObject {
	enum State {
		case loading
		case failure(KukaiError, String)
		case success(String?)
		
		/**
		State uses assocaited types inside .failure to return error messages. This makes it impossible to run logic like `if state != .loading`.
		As a temporary workaround, the `isLoading` function wraps up an `if case` check to simplify comparision logic
		*/
		func isLoading() -> Bool {
			if case .loading = self { // 'case' can only be used inside if or switch
				return true
			}
			
			return false
		}
	}
	
	@Published var state = State.loading
}


/**
 Swift 6 has annoyingly updated DiffableDatasources to require `Sendable` conformance, and listed `AnyHashable` as not-sendable, bringing with it an absolute shit tonne of issues,
 due to the fact that we are using AnyHashable EVERYWHERE as the base type of diffable datasource. So first things first, we created a wrapper struct that takes in any existing Hashable
 (which is what all our types currently are), and converts it to a hashable & sendable struct.
 
 Unlike the existing AnyHashable, this can't be cast or infered. So anywhere we were casting now needs to call the property `base` and cast that instead
 
 We also can't create arrays or append items in the same way as everything now also requires calling `init` explictily. So below we have created some custom collections, to allow all the
 existing code to stay as is (.append(), .enumerated(), subscript, etc), but it does require switching the type from `[AnyHashable]` to `AnyHashableSendableArray`, or
 `[[AnyHashbale]]` to `AnyHashableSendable2DArray`
 */
public struct AnyHashableSendable: Hashable, Sendable {
	
	public let base: any Hashable & Sendable
	
	public init<H>(_ base: H) where H : Hashable {
		self.base = base
	}
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		AnyHashable(lhs.base) == AnyHashable(rhs.base)
	}
	
	public func hash(into hasher: inout Hasher) {
		base.hash(into: &hasher)
	}
}

/**
 A custom collection object to hold an array of `AnyHashableSendable` with some helper methods to allow it to function the way the exist code was expecting to use `[AnyHashable]`
 */
public struct AnyHashableSendableArray: Collection, Hashable, Sendable {
	public typealias Index = Int
	public typealias Element = AnyHashableSendable
	
	public var startIndex: Index { return storage.startIndex }
	public var endIndex: Index { return storage.endIndex }
	
	private var storage: [Element] = []
	
	init<T: Hashable>(_ storage: [T]) {
		self.storage = storage.map({ .init($0) })
	}
	
	public subscript(index: Index) -> Iterator.Element {
		get { return storage[index] }
		set { storage[index] = .init(newValue) }
	}
	
	public func index(after i: Index) -> Index {
		return storage.index(after: i)
	}
	
	public mutating func append<T: Hashable>(_ item: T) {
		storage.append(.init(item))
	}
}

/**
 A custom collection object to hold an array of `[AnyHashableSendable]` with some helper methods to allow it to function the way the exist code was expecting to use `[[AnyHashable]]`
 */
public struct AnyHashableSendable2DArray: Collection, Hashable, Sendable {
	public typealias Index = Int
	public typealias Element = AnyHashableSendableArray
	
	public var startIndex: Index { return storage.startIndex }
	public var endIndex: Index { return storage.endIndex }
	
	private var storage: [Element] = []
	
	init(_ storage: [AnyHashableSendableArray]) {
		self.storage = storage
	}
	
	public subscript(index: Index) -> Iterator.Element {
		get { return storage[index] }
		set { storage[index] = newValue }
	}
	
	public func index(after i: Index) -> Index {
		return storage.index(after: i)
	}
	
	public mutating func append(_ item: [AnyHashable]) {
		storage.append(AnyHashableSendableArray(item))
	}
	
	public func enumerated() -> [(Index, [AnyHashableSendable])] {
		return storage.enumerated().map { (index, element) in
			return (index, element.map({ $0 }))
		}
	}
}

/**
 Custom MVVM Diffable datasource protocol handler for a tableView
 */
public protocol UITableViewDiffableDataSourceHandler {
	associatedtype SectionEnum: Hashable
	associatedtype CellDataType: Hashable, Sendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withTableView tableView: UITableView)
	func refresh(animate: Bool, successMessage: String?)
}

/**
 Custom MVVM Diffable datasource protocol handler for a collectionView
 */
public protocol UICollectionViewDiffableDataSourceHandler {
	associatedtype SectionEnum: Hashable
	associatedtype CellDataType: Hashable
	
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withCollectionView collectionView: UICollectionView)
	func refresh(animate: Bool, successMessage: String?)
}
