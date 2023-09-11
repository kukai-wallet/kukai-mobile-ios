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
			
			if let obj = item as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionCell", for: indexPath) as? SideMenuOptionCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle ?? ""
				return cell
				
			} else if let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuAboutCell", for: indexPath) as? SideMenuAboutCell {
				cell.setup()
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
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		var options: [AnyHashable] = []
		options = [
			SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Settings", subtitle: nil, id: "settings"),
			SideMenuOptionData(icon: UIImage(named: "Security") ?? UIImage.unknownToken(), title: "Security", subtitle: nil, id: "security"),
			SideMenuOptionData(icon: UIImage(named: "ConnectApps") ?? UIImage.unknownToken(), title: "Connected Apps", subtitle: nil, id: "connected"),
			SideMenuOptionData(icon: UIImage(named: "Contacts") ?? UIImage.unknownToken(), title: "Feedback & Support", subtitle: nil, id: "feedback"),
			SideMenuOptionData(icon: UIImage(named: "Share") ?? UIImage.unknownToken(), title: "Tell Others about Kukai", subtitle: nil, id: "share"),
			
			/*
			SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: "Wallet Connect", subtitle: nil, id: "wc2"),
			*/
		]
		
		
		
		options.append(UUID())
		
		snapshot.appendItems(options, toSection: 0)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> (segue: String, collapseAndNavigate: Bool)? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData else {
			return nil
		}
		
		switch obj.id {
			case "settings":
				return (segue: "side-menu-settings", collapseAndNavigate: true)
				
			case "security":
				return (segue: "side-menu-security", collapseAndNavigate: true)
				
			/*
			case "wc2":
				return (segue: "side-menu-wallet-connect", collapseAndNavigate: true)
			*/
			default:
				return nil
		}
	}
}
