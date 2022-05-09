//
//  BeaconViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class BeaconViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
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
		let selectedNetwork = DependencyManager.shared.currentNetworkType.rawValue
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		snapshot.appendItems([TitleSubtitleObj(title: "Selected Currency", subtitle: selectedCurrency)], toSection: 0)
		snapshot.appendItems([TitleSubtitleObj(title: "Theme", subtitle: selectedTheme)], toSection: 0)
		snapshot.appendItems([TitleSubtitleObj(title: "Network", subtitle: selectedNetwork)], toSection: 0)
		snapshot.appendItems([TitleSubtitleObj(title: "Beacon", subtitle: "")], toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		// Return success
		self.state = .success(nil)
	}
}
