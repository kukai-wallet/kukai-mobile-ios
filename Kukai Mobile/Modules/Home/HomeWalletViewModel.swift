//
//  HomeWalletViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2021.
//

import UIKit
import KukaiCoreSwift
import OSLog

enum HomeWalletSection: CaseIterable {
	case balance
	case tokens
	case nfts
}

class HomeWalletViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	typealias SectionEnum = HomeWalletSection
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<HomeWalletSection, AnyHashable>? = nil
	var walletAddress: String = ""
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let xtzBalance = item as? XTZAmount {
				let cell = tableView.dequeueReusableCell(withIdentifier: "xtzBalanceCell", for: indexPath) as? XTZBalanceTableViewCell
				cell?.balanceLabel.text = xtzBalance.normalisedRepresentation
				return cell
				
			} else if let token = item as? Token, token.nfts == nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
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
	}
	
	func refresh(animate: Bool) {
		guard let ds = dataSource else {
			state = .failure(ErrorResponse.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		guard let address = WalletCacheService().fetchPrimaryWallet()?.address else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		walletAddress = address
		DependencyManager.shared.betterCallDevClient.fetchAccountInfo(forAddress: address) { [weak self] result in
			switch result {
				case .failure(let error):
					self?.state = .failure(error, "Unable to fetch data. Please check internet connection and try again")
					
				case .success(let account):
					self?.processAccount(account, forDataSource: ds, animate: animate)
			}
		}
	}
	
	private func processAccount(_ account: Account, forDataSource ds: UITableViewDiffableDataSource<HomeWalletSection, CellDataType>, animate: Bool) {
		var snapshot = NSDiffableDataSourceSnapshot<HomeWalletSection, AnyHashable>()
		snapshot.appendSections(HomeWalletSection.allCases)
		
		
		snapshot.appendItems([account.xtzBalance], toSection: .balance)
		snapshot.appendItems(account.tokens, toSection: .tokens)
		
		var nftArray: [AnyHashable] = []
		for nftToken in account.nfts {
			nftArray.append(nftToken)
			
			for nft in nftToken.nfts ?? [] {
				nftArray.append(nft)
			}
		}
		
		snapshot.appendItems(nftArray, toSection: .nfts)
		state = .success
		
		ds.apply(snapshot, animatingDifferences: animate)
	}
}
