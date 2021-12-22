//
//  AssetsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/12/2021.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class AssetsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var networkChangeCancellable: AnyCancellable?
	private var walletChangeCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var walletAddress: String = ""
	
	var account: Account? = nil
	
	
	
	// MARk: - Init
	
	override init() {
		super.init()
		
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
	}
	
	deinit {
		networkChangeCancellable?.cancel()
		walletChangeCancellable?.cancel()
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let xtzBalance = item as? XTZAmount {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
				cell?.iconView.image = UIImage(named: "tezos-xtz-logo")
				cell?.amountLabel.text = xtzBalance.normalisedRepresentation
				cell?.symbolLabel.text = "XTZ"
				return cell
				
			} else if let token = item as? Token, token.nfts == nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "tokenBalanceCell", for: indexPath) as? TokenBalanceTableViewCell
				cell?.iconView.setKuakiImage(withURL: token.thumbnailURL, downSampleStandardImage: (width: 30, height: 30))
				cell?.amountLabel.text = token.balance.normalisedRepresentation
				cell?.symbolLabel.text = token.symbol
				return cell
				
			} else if let token = item as? Token, token.nfts != nil {
				let cell = tableView.dequeueReusableCell(withIdentifier: "nftParentCell", for: indexPath) as? NftParentTableViewCell
				cell?.titleLabel.text = token.name
				return cell
				
			} else if let nft = item as? NFT {
				let cell = tableView.dequeueReusableCell(withIdentifier: "nftChildCell", for: indexPath) as? NftChildTableViewCell
				cell?.iconView.setKuakiImage(withURL: nft.thumbnailURL, downSampleStandardImage: nil)
				cell?.titleLabel.text = nft.name
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
		
		guard let address = DependencyManager.shared.selectedWallet?.address, let ds = dataSource else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to locate wallet")
			return
		}
		
		walletAddress = address
		
		DependencyManager.shared.betterCallDevClient.fetchAccountInfo(forAddress: address) { [weak self] result in
			guard let acc = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data. Please check internet connection and try again")
				return
			}
			
			self?.account = acc
			
			
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections([0])
			
			var tokens: [AnyHashable] = [acc.xtzBalance]
			tokens.append(contentsOf: acc.tokens)
			
			snapshot.appendItems(tokens, toSection: 0)
			
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success(nil)
		}
	}
}
