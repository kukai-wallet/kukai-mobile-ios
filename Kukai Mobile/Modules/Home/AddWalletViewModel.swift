//
//  AddWalletViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/05/2024.
//

import UIKit

struct AddCellData: Hashable {
	let id = UUID()
	let image: UIImage?
	let title: String
	let subtitle: String
	let isExpandable: Bool
	let isTopLevel: Bool
	let option: String?
}

class AddWalletViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var expandedIndex: IndexPath? = nil
	
	let sectionTitles: [String?] = [
		"Accounts",
		"Wallets",
		nil
	]
	
	let headings: [[AnyHashable]] = [
		[
			AddCellData(image: UIImage(named: "btnAddKnockout"), title: "Add account to existing wallet", subtitle: "Add another account to the same recovery phrase", isExpandable: false, isTopLevel: true, option: "account")
		],
		[
			AddCellData(image: UIImage(named: "ArrowOval"), title: "Create a New Wallet", subtitle: "Create a brand new wallet", isExpandable: true, isTopLevel: true, option: nil)
		],
		[
			AddCellData(image: UIImage(named: "AddNewAccount"), title: "Add Existing Wallet", subtitle: "Import a wallet you've previously setup", isExpandable: true, isTopLevel: true, option: nil)
		]
	]
	
	let innerOptions: [[AnyHashable]] = [
		[],
		[
			AddCellData(image: UIImage(named: "WalletSocial"), title: "Use Social", subtitle: "Sign in with your preferred social account", isExpandable: false, isTopLevel: false, option: "social"),
			AddCellData(image: UIImage(named: "WalletHD"), title: "HD Wallet", subtitle: "Create a new HD wallet and recovery phrase", isExpandable: false, isTopLevel: false, option: "hd"),
		],
		[
			AddCellData(image: UIImage(named: "WalletSocial"), title: "Use Social", subtitle: "Sign in with your preferred social account", isExpandable: false, isTopLevel: false, option: "social"),
			AddCellData(image: UIImage(named: "WalletRestore"), title: "Restore with Recovery Phrase", subtitle: "Import accounts using your recovery phrase from Kukai or another wallet", isExpandable: false, isTopLevel: false, option: "import"),
			AddCellData(image: UIImage(named: "WalletLedger"), title: "Connect with Ledger", subtitle: "Add accounts from your Bluetooth hardware wallet", isExpandable: false, isTopLevel: false, option: "ledger"),
			AddCellData(image: UIImage(named: "WalletHD"), title: "Restore with Private Key", subtitle: "Import a wallet from a private key", isExpandable: false, isTopLevel: false, option: "private-key"),
			AddCellData(image: UIImage(named: "WalletWatch"), title: "Watch a Tezos Address", subtitle: "Watch a public address or .tez domain", isExpandable: false, isTopLevel: false, option: "watch")
		]
	]
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsAddHeaderCell", for: indexPath) as? AccountsAddHeaderCell {
				cell.titleLabel.text = obj
				return cell
				
			} else if let obj = item as? AddCellData, obj.isTopLevel, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsAddOptionCell", for: indexPath) as? AccountsAddOptionCell {
				cell.iconView.image = obj.image
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle
				return cell
				
			} else if let obj = item as? AddCellData, let cell = tableView.dequeueReusableCell(withIdentifier: "AccountsAddOptionCell_inner", for: indexPath) as? AccountsAddOptionCell {
				cell.iconView.image = obj.image
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.subtitle
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections(Array(0..<self.headings.count))
		
		for (index, heading) in headings.enumerated() {
			snapshot.appendItems(heading, toSection: index)
		}
		
		if let expanded = expandedIndex {
			snapshot.appendItems(innerOptions[expanded.section], toSection: expanded.section)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func handleTap(atIndexPath: IndexPath) -> String? {
		guard let item = dataSource?.itemIdentifier(for: atIndexPath) as? AddCellData else {
			return nil
		}
		
		if item.isExpandable, expandedIndex == atIndexPath {
			close(section: atIndexPath.section)
			expandedIndex = nil
			return nil
			
		} else if item.isExpandable {
			if let expanded = expandedIndex {
				close(section: expanded.section)
			}
			open(section: atIndexPath.section)
			expandedIndex = atIndexPath
			return nil
			
		} else {
			return item.option
		}
	}
	
	private func open(section: Int) {
		var currentSnapshot = dataSource?.snapshot()
		currentSnapshot?.appendItems(innerOptions[section], toSection: section)
		
		if let snap = currentSnapshot {
			dataSource?.apply(snap, animatingDifferences: true)
		}
	}
	
	private func close(section: Int) {
		var currentSnapshot = dataSource?.snapshot()
		currentSnapshot?.deleteItems(innerOptions[section])
		
		if let snap = currentSnapshot {
			dataSource?.apply(snap, animatingDifferences: true)
		}
	}
}
