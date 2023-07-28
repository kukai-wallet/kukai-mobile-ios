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
	let id: String
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
		let selectedNetwork = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Ghostnet"
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		
		let themeImage = (selectedTheme == "Dark" ? UIImage(named: "Darkmode") : UIImage(named: "Lightmode")) ?? UIImage.unknownToken()
		var options = [
			SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: "Wallet Connect", subtitle: nil, id: "wc2"),
			SideMenuOptionData(icon: themeImage, title: "Theme", subtitle: selectedTheme, id: "theme"),
			SideMenuOptionData(icon: UIImage(named: "Currency") ?? UIImage.unknownToken(), title: "Currency", subtitle: selectedCurrency, id: "currency"),
			SideMenuOptionData(icon: UIImage(named: "Network") ?? UIImage.unknownToken(), title: "Network", subtitle: selectedNetwork, id: "network"),
		]
		
		if CurrentDevice.biometricTypeAuthorized() != .unavailable {
			let biometricType = CurrentDevice.biometricTypeSupported()
			let title = biometricType == .faceID ? "Face ID" : "Touch ID"
			let image = biometricType == .faceID ? UIImage(systemName: "faceid") : UIImage(systemName: "touchid")
			var enabledText = StorageService.isBiometricEnabled() ? "Enabled" : "Disabled"
			if CurrentDevice.biometricTypeAuthorized() == .none {
				enabledText = "Not Authorized"
			}
			
			options.append(SideMenuOptionData(icon: image ?? UIImage.unknownToken(), title: title, subtitle: enabledText, id: "biometric"))
		}
		
		snapshot.appendItems(options, toSection: 0)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> (segue: String, collapseAndNavigate: Bool)? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData else {
			return nil
		}
		
		switch obj.id {
			case "wc2":
				return (segue: "side-menu-wallet-connect", collapseAndNavigate: true)
				
			case "theme":
				return (segue: "theme", collapseAndNavigate: false)
				
			case "currency":
				return (segue: "side-menu-currency", collapseAndNavigate: true)
				
			case "network":
				return (segue: "side-menu-network", collapseAndNavigate: false)
				
			case "biometric":
				if CurrentDevice.biometricTypeAuthorized() == .none {
					return nil
					
				} else {
					return (segue: "biometric", collapseAndNavigate: false)
				}
				
			default:
				return nil
		}
	}
	
	func isBiometricCell(forIndexPath: IndexPath) -> Bool {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData else {
			return false
		}
		
		return obj.id == "biometric"
	}
}
