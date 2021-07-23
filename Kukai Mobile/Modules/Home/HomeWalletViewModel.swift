//
//  HomeWalletViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2021.
//

import UIKit

enum HomeWalletSection: CaseIterable {
	case balance
	case tokens
	case nfts
}

class HomeWalletViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = HomeWalletSection
	typealias CellDataType = AnyHashable
	
	func makeDataSource(withTableView tableView: UITableView) -> UITableViewDiffableDataSource<HomeWalletSection, AnyHashable> {
		return UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			// xtzBalanceCell
			// tokenBalanceCell
			// nftParentCell
			// nftChildCell
			
			
			/*
			if let diffItem = item as? DiffTest {
				let cell = tableView.dequeueReusableCell(withIdentifier: "blah", for: indexPath)
				cell.textLabel?.text = diffItem.name
				
				return cell
			}
			*/
			
			return UITableViewCell()
		})
	}
	
	func refresh(dataSource: UITableViewDataSource?, animate: Bool) {
		guard let ds = dataSource as? UITableViewDiffableDataSource<HomeWalletSection, CellDataType> else {
			state = .failure(ViewModelError.invalidDataSourcePassedToRefresh, "Uh oh!")
			return
		}
		
		
		state = .loading
		
		// do network request
		
		var snapshot = NSDiffableDataSourceSnapshot<HomeWalletSection, AnyHashable>()
		snapshot.appendSections(HomeWalletSection.allCases)

		snapshot.appendItems([], toSection: .balance)
		snapshot.appendItems([], toSection: .tokens)
		snapshot.appendItems([], toSection: .nfts)
		state = .success
		
		ds.apply(snapshot, animatingDifferences: animate)
	}
}
