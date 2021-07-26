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
		case failure(ErrorResponse, String)
		case success
	}
	
	@Published var state = State.loading
}

public protocol UITableViewDiffableDataSourceHandler {
	associatedtype SectionEnum: CaseIterable, Hashable
	associatedtype CellDataType: Hashable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withTableView tableView: UITableView)
	func refresh(animate: Bool)
}

public protocol UICollectionViewDiffableDataSourceHandler {
	associatedtype SectionEnum: CaseIterable, Hashable
	associatedtype CellDataType: Hashable
	
	var dataSource: UICollectionViewDiffableDataSource<SectionEnum, CellDataType>? { get }
	
	func makeDataSource(withCollectionView collectionView: UICollectionView)
	func refresh(animate: Bool)
}
