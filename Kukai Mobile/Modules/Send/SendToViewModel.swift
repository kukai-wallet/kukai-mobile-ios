//
//  SendToViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct WalletObj: Hashable {
	let icon: UIImage?
	let title: String
	let address: String
}

class SendToViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var walletObjs: [WalletObj] = []
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			if let obj = item as? WalletObj, let cell = tableView.dequeueReusableCell(withIdentifier: "AddressChoiceCell", for: indexPath) as? AddressChoiceCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.address
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address, let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		// Build arrays of data
		let wallets = WalletCacheService().fetchWallets() ?? []
		walletObjs = []
		
		for wallet in wallets where wallet.address != address {
			
			if let tw = wallet as? TorusWallet {
				walletObjs.append(WalletObj(icon: UIImage(named: "tezos-xtz-logo"), title: tw.socialUsername ?? tw.address, address: tw.address))
				
			} else {
				walletObjs.append(WalletObj(icon: UIImage(named: "tezos-xtz-logo"), title: wallet.address, address: wallet.address))
			}
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0, 1])
		
		snapshot.appendItems([], toSection: 0)
		snapshot.appendItems(walletObjs, toSection: 1)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		state = .success(nil)
	}
	
	func heightForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> CGFloat {
		let view = viewForHeaderInSection(section, forTableView: tableView)
		view.sizeToFit()
		
		return view.frame.size.height
	}
	
	func viewForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> UIView {
		
		if section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell") as? ImageHeadingCell {
			cell.iconView.image = UIImage(systemName: "person.crop.circle")
			cell.headingLabel.text = "Contacts"
			return cell.contentView
			
		} else if section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell") as? ImageHeadingCell {
			cell.iconView.image = UIImage(systemName: "folder.fill")
			cell.headingLabel.text = "My Wallets"
			return cell.contentView
			
		} else {
			return UIView()
		}
	}
	
	func address(forIndexPath indexPath: IndexPath) -> String {
		return walletObjs[indexPath.row].address
	}
}
