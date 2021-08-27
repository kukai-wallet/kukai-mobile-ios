//
//  HomeWalletViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2021.
//

import UIKit
import Combine
import KukaiCoreSwift
import OSLog

class HomeWalletViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var networkChangeCancellable: AnyCancellable?
	private var walletChangeCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var walletAddress: String = ""
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		networkChangeCancellable = DependencyManager.shared.$networkDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refresh(animate: true)
			}
		
		walletChangeCancellable = DependencyManager.shared.$walletDidChange
			.dropFirst()
			.sink { [weak self] _ in
				self?.refresh(animate: true)
			}
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let xtzBalance = item as? XTZAmount {
				let cell = tableView.dequeueReusableCell(withIdentifier: "xtzBalanceCell", for: indexPath) as? XTZBalanceTableViewCell
				cell?.balanceLabel.text = xtzBalance.normalisedRepresentation
				return cell
				
			} else if let token = item as? Token, token.nfts == nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
				cell?.iconView.setImageToCurrentSize(url: token.thumbnailURL)
				cell?.amountLabel.text = token.balance.normalisedRepresentation
				cell?.symbolLabel.text = token.symbol
				return cell
				
			} else if let token = item as? Token, token.nfts != nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "nftParentCell", for: indexPath) as? NftParentTableViewCell
				cell?.titleLabel.text = token.name
				return cell
				
			} else if let nft = item as? NFT {
				let cell = tableView.dequeueReusableCell(withIdentifier: "nftChildCell", for: indexPath) as? NftChildTableViewCell
				cell?.titleLabel.text = nft.name
				return cell
				
			} else {
				os_log("Invalid Hashable: %@", log: .default, type: .debug, "\(item)")
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		walletAddress = address
		DependencyManager.shared.betterCallDevClient.fetchAccountInfo(forAddress: address) { [weak self] result in
			guard let account = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data. Please check internet connection and try again")
				return
			}
			
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections(Array(0...account.nfts.count+2))
			
			snapshot.appendItems([account.xtzBalance], toSection: 0)
			snapshot.appendItems(account.tokens, toSection: 1)
			
			for (index, nft) in account.nfts.enumerated() {
				var nfts: [AnyHashable] = [nft]
				nfts.append(contentsOf: nft.nfts ?? [])
				
				snapshot.appendItems(nfts, toSection: index+2)
			}
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success
		}
	}
}
