//
//  SideMenuSettingsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/09/2023.
//

import UIKit
import KukaiCoreSwift

class SideMenuSettingsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionCell", for: indexPath) as? SideMenuOptionCell {
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
		let themeImage = (selectedTheme == "Dark" ? UIImage(named: "Darkmode") : UIImage(named: "Lightmode")) ?? UIImage.unknownToken()
		let selectedNetwork = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
		
		let imageCacheSize = MediaProxyService.sizeOf(cache: .temporary).description
		let int64 = Int64(imageCacheSize) ?? 0
		let collectibleStorageSize = ByteCountFormatter().string(fromByteCount: int64)
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0, 1, 2, 3, 4])
		
		snapshot.appendItems([.init(SideMenuOptionData(icon: UIImage(named: "Network") ?? UIImage.unknownToken(), title: "Network", subtitle: selectedNetwork, subtitleIsWarning: false, id: "network"))], toSection: 0)
		snapshot.appendItems([.init(SideMenuOptionData(icon: UIImage(named: "Currency") ?? UIImage.unknownToken(), title: "Currency", subtitle: selectedCurrency, subtitleIsWarning: false, id: "currency"))], toSection: 1)
		snapshot.appendItems([.init(SideMenuOptionData(icon: themeImage, title: "Theme", subtitle: selectedTheme, subtitleIsWarning: false, id: "theme"))], toSection: 2)
		snapshot.appendItems([.init(SideMenuOptionData(icon: UIImage(named: "Storage") ?? UIImage.unknownToken(), title: "Storage", subtitle: collectibleStorageSize, subtitleIsWarning: false, id: "storage"))], toSection: 3)
		snapshot.appendItems([.init(SideMenuOptionData(icon: UIImage(named: "Storage") ?? UIImage.unknownToken(), title: "Activity Domains and Aliases", subtitle: "", subtitleIsWarning: false, id: "lookup"))], toSection: 4)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> String? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath)?.base as? SideMenuOptionData else {
			return nil
		}
		
		return obj.id
	}
}
