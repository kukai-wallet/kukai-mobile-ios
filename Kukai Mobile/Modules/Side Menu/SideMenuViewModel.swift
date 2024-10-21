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
	let subtitleIsWarning: Bool
	let id: String
}

struct SideMenuResponse {
	let segue: String?
	let collapseAndNavigate: Bool?
	let url: URL?
	let isSecure: Bool
}

struct SpacerObj: Hashable {
	let id = UUID()
}

class SideMenuViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? SideMenuOptionData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath) as? SideMenuCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle ?? ""
				return cell
				
			} else if let _ = item.base as? SpacerObj {
				return tableView.dequeueReusableCell(withIdentifier: "spacerCell", for: indexPath)
				
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
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0])
		
		var options: [AnyHashableSendable] = []
		options = [
			.init(SideMenuOptionData(icon: UIImage(named: "ConnectApps") ?? UIImage.unknownToken(), title: "Connected Apps", subtitle: nil, subtitleIsWarning: false, id: "connected")),
			.init(SideMenuOptionData(icon: UIImage(named: "GearSolid") ?? UIImage.unknownToken(), title: "Settings", subtitle: nil, subtitleIsWarning: false, id: "settings")),
			.init(SideMenuOptionData(icon: UIImage(named: "Security") ?? UIImage.unknownToken(), title: "Security", subtitle: nil, subtitleIsWarning: false, id: "security")),
			.init(SpacerObj()),
			.init(SideMenuOptionData(icon: UIImage(named: "Contacts") ?? UIImage.unknownToken(), title: "Feedback & Support", subtitle: nil, subtitleIsWarning: false, id: "feedback")),
			.init(SideMenuOptionData(icon: UIImage(named: "Share") ?? UIImage.unknownToken(), title: "Tell Others about Kukai", subtitle: nil, subtitleIsWarning: false, id: "share")),
			.init(SpacerObj()),
		]
		
		options.append(.init(UUID()))
		
		snapshot.appendItems(options, toSection: 0)
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func details(forIndexPath: IndexPath) -> SideMenuResponse? {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath)?.base as? SideMenuOptionData else {
			return nil
		}
		
		switch obj.id {
			case "settings":
				return SideMenuResponse(segue: "side-menu-settings", collapseAndNavigate: true, url: nil, isSecure: false)
				
			case "security":
				return SideMenuResponse(segue: "side-menu-security", collapseAndNavigate: true, url: nil, isSecure: true)
			
			case "connected":
				return SideMenuResponse(segue: "connected-apps", collapseAndNavigate: true, url: nil, isSecure: false)
				
			case "feedback":
				let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
				let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
				let os = UIDevice.current.systemVersion
				let device = UIDevice.current.modelName
				
				let subject = "Kukai iOS Feedback"
				let body = "\n\n\n\n\n ==================== \nApp Version: v\(version) (\(build)) \nOS Version: \(os) \nModel: \(device)"
				let coded = "mailto:contact@kukai.app?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
				if let emailURL = URL(string: coded) {
					return SideMenuResponse(segue: nil, collapseAndNavigate: false, url: emailURL, isSecure: false)
				}
				
			case "share":
				return SideMenuResponse(segue: nil, collapseAndNavigate: false, url: nil, isSecure: false)
				
			default:
				return nil
		}
		
		return nil
	}
}
