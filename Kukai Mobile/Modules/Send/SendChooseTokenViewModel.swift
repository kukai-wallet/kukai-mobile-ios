//
//  SendChooseTokenViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class SendChooseTokenViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var account: Account? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let xtzBalance = item as? XTZAmount {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
				cell?.iconView.image = UIImage(named: "tezos-xtz-logo")
				cell?.amountLabel.text = xtzBalance.normalisedRepresentation
				cell?.symbolLabel.text = "XTZ"
				return cell
				
			} else if let token = item as? Token, token.nfts == nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
				MediaProxyService.load(url: token.thumbnailURL, to: cell?.iconView ?? UIImageView(), fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: (width: 30, height: 30))
				cell?.amountLabel.text = token.balance.normalisedRepresentation
				cell?.symbolLabel.text = token.symbol
				return cell
				
			} else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		//self.account = DependencyManager.shared.betterCallDevClient.cachedAccountInfo()
		self.updateTableView(animate: animate)
	}
	
	func updateTableView(animate: Bool) {
		guard let ds = dataSource, let acc = account else {
			state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0])
		
		var tokens: [AnyHashable] = [acc.xtzBalance]
		tokens.append(contentsOf: acc.tokens)
		
		snapshot.appendItems(tokens, toSection: 0)
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(nil)
	}
	
	func token(forIndexPath indexPath: IndexPath) -> Token? {
		if indexPath.row == 0 {
			return Token.xtz()
			
		} else if let token = account?.tokens[indexPath.row] {
			return token
		}
		
		return nil
	}
}
