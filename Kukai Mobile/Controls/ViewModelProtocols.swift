//
//  ViewModel.swift
//  MagmaWallet
//
//  Created by Simon Mcloughlin on 09/01/2020.
//  Copyright © 2020 camlCase Inc. All rights reserved.
//

import UIKit
import Combine

public enum ViewModelError: Error {
	case invalidDataSourcePassedToRefresh
}

public class ViewModel: ObservableObject {
	enum State {
		case loading
		case failure(Error, String)
		case success
	}
	
	@Published var state = State.loading
}

protocol UITableViewDiffableDataSourceHandler {
	associatedtype SectionEnum: CaseIterable, Hashable
	associatedtype CellDataType: Hashable
	
	func makeDataSource(withTableView tableView: UITableView) -> UITableViewDiffableDataSource<SectionEnum, CellDataType>
	func refresh(dataSource: UITableViewDataSource?, animate: Bool)
}

protocol UICollectionViewDiffableDataSourceHandler {
	associatedtype SectionEnum: CaseIterable, Hashable
	associatedtype CellDataType: Hashable
	
	func makeDataSource(withCollectionView collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<SectionEnum, CellDataType>
	func refresh(dataSource: UICollectionViewDataSource?, animate: Bool)
}
