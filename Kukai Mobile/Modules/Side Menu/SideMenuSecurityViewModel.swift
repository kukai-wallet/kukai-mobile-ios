//
//  SideMenuSecurityViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/09/2023.
//

import UIKit
import KukaiCoreSwift

struct SideMenuOptionToggleData: Hashable {
	let icon: UIImage
	let title: String
	let toggleOn: Bool
	let id: String
}

class SideMenuSecurityViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
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
				
			} else if let obj = item as? SideMenuOptionToggleData, let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuOptionToggleCell", for: indexPath) as? SideMenuOptionCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.toggle?.isOn = obj.toggleOn
				cell.delegate = self
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
		var options: [[AnyHashable]] = []
		
		if CurrentDevice.biometricTypeAuthorized() != .unavailable && StorageService.wasBiometricsAccessibleDuringOnboarding() {
			let biometricType = CurrentDevice.biometricTypeSupported()
			let title = biometricType == .faceID ? "Face ID" : "Touch ID"
			let image = biometricType == .faceID ? UIImage(systemName: "faceid") : UIImage(systemName: "touchid")
			
			if CurrentDevice.biometricTypeAuthorized() == .none {
				options.append([SideMenuOptionData(icon: image ?? UIImage.unknownToken(), title: title, subtitle: "Not Authorized", subtitleIsWarning: false, id: "biometric-not-auth")])
			} else {
				options.append([SideMenuOptionToggleData(icon: image ?? UIImage.unknownToken(), title: title, toggleOn: StorageService.isBiometricEnabled(), id: "biometric")])
			}
		}
		
		options.append(contentsOf: [
			[SideMenuOptionData(icon: UIImage(named: "Kukai") ?? UIImage.unknownToken(), title: "Kukai Passcode", subtitle: nil, subtitleIsWarning: false, id: "passcode")],
			[SideMenuOptionData(icon: UIImage(named: "Wallet") ?? UIImage.unknownToken(), title: "Back Up", subtitle: nil, subtitleIsWarning: false, id: "backup")],
			[SideMenuOptionData(icon: UIImage(named: "Reset") ?? UIImage.unknownToken(), title: "Reset App", subtitle: nil, subtitleIsWarning: false, id: "reset")]
		])
		
		snapshot.appendSections(Array(0..<options.count))
		
		for (index, opt) in options.enumerated() {
			snapshot.appendItems(opt, toSection: index)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> (segue: String?, url: URL?) {
		if isBiometricNotAuthCell(forIndexPath: forIndexPath), let settingsURL = URL(string: UIApplication.openSettingsURLString) {
			return (segue: nil, url: settingsURL)
			
		} else if isBiometricCell(forIndexPath: forIndexPath) {
			return (segue: nil, url: nil)
			
		} else if let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData {
			return (segue: obj.id, url: nil)
		}
		
		return (segue: nil, url: nil)
	}
	
	func isBiometricCell(forIndexPath: IndexPath) -> Bool {
		guard let _ = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionToggleData else {
			return false
		}
		
		return true
	}
	
	func isBiometricNotAuthCell(forIndexPath: IndexPath) -> Bool {
		guard let obj = dataSource?.itemIdentifier(for: forIndexPath) as? SideMenuOptionData, obj.id == "biometric-not-auth" else {
			return false
		}
		
		return true
	}
}

extension SideMenuSecurityViewModel: SideMenuOptionToggleDelegate {
	
	func sideMenuToggleChangedTo(isOn: Bool, forTitle: String) {
		FaceIdViewController.handleBiometricChangeTo(isOn: isOn) { [weak self] errorMessage in
			if let _ = errorMessage {
				self?.refresh(animate: true)
			}
		}
	}
}
