//
//  SideMenuViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/03/2023.
//

import UIKit
import KukaiCoreSwift

struct SideMenuOptionData: Hashable {
	let icon: UIImage
	let title: String
	let subtitle: String?
}

class SideMenuViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let  obj = item as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionCell", for: indexPath) as? SideMenuOptionCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle ?? ""
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		let selectedCurrency = DependencyManager.shared.coinGeckoService.selectedCurrency.uppercased()
		let selectedTheme = ThemeManager.shared.currentTheme()
		let selectedNetwork = DependencyManager.shared.currentNetworkType.rawValue
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		let options = [
			SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Wallet Connect", subtitle: nil),
			SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Theme", subtitle: selectedTheme),
			SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Currency", subtitle: selectedCurrency),
			SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Network", subtitle: selectedNetwork),
		]
		
		snapshot.appendItems(options, toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> String? {
		if forIndexPath.row == 0 {
			return "side-menu-wallet-connect"
			
		} else if forIndexPath.row == 1 {
			return "side-menu-theme"
			
		} else if forIndexPath.row == 2 {
			return "side-menu-currency"
			
		} else if forIndexPath.row == 3 {
			return "side-menu-network"
			
		}
		
		return nil
	}
}
