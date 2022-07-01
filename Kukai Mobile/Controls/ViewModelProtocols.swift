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
		State uses assocaited types inside .failure to return error messages. THis makes it impossible to run logic like `if state != .loading`.
		As a temporary workaround, the `isLoading` function wraps up an `if case` check to simply comparision logic
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

public protocol UITableViewDiffableDataSourceHandler {
	associatedtype SectionEnum: Hashable
	associatedtype CellDataType: Hashable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withTableView tableView: UITableView)
	func refresh(animate: Bool, successMessage: String?)
}

public protocol UICollectionViewDiffableDataSourceHandler {
	associatedtype SectionEnum: CaseIterable, Hashable
	associatedtype CellDataType: Hashable
	
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withCollectionView collectionView: UICollectionView)
	func refresh(animate: Bool, successMessage: String?)
}
