//
//  ProfileViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct TitleSubtitleObj: Hashable {
	let title: String
	let subtitle: String
}

class ProfileViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var fetchingDataCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	
	
	// MARK: Init
	
	/*
	override init() {
		super.init()
		
		fetchingDataCancellable = DependencyManager.shared.balanceService.$isFetchingData
			.dropFirst()
			.sink { [weak self] value in
				guard let self = self else { return }
				
				if value, !self.state.isLoading() {
					self.state = .loading
					
				} else if !value {
					self.refresh(animate: true)
				}
			}
	}
	
	deinit {
		fetchingDataCancellable?.cancel()
	}
	*/
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			if let obj = item as? TitleSubtitleObj, let cell = tableView.dequeueReusableCell(withIdentifier: "TitleSubtitleCell", for: indexPath) as? TitleSubtitleCell {
				cell.titleLabel.text = obj.title
				cell.subTitleLabel.text = obj.subtitle
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			self.state = .failure(ErrorResponse.unknownError(), "Unable to find datasource")
			return
		}
		
		let selectedCurrency = DependencyManager.shared.coinGeckoService.selectedCurrency.uppercased()
		let selectedTheme = ThemeManager.shared.currentTheme()
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		snapshot.appendItems([TitleSubtitleObj(title: "Selected Currency", subtitle: selectedCurrency)], toSection: 0)
		snapshot.appendItems([TitleSubtitleObj(title: "Theme", subtitle: selectedTheme)], toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		// Return success
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> String {
		if forIndexPath.row == 0 {
			return "currency"
			
		} else {
			return "theme"
		}
	}
}
