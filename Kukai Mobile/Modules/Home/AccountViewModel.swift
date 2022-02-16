//
//  AccountViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class AccountViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var networkChangeCancellable: AnyCancellable?
	private var walletChangeCancellable: AnyCancellable?
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
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
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let token = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceCell", for: indexPath) as? TokenBalanceCell {
				MediaProxyService.load(url: token.thumbnailURL, to: cell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: (width: 40, height: 40))
				
				cell.symbolLabel.text = token.symbol
				cell.balanceLabel.text = token.balance.normalisedRepresentation
				cell.rateLabel.text = "1 == 0 XTZ"
				cell.valuelabel.text = "$0.00"
				return cell
				
			} else if let amount = item as? XTZAmount, let cell = tableView.dequeueReusableCell(withIdentifier: "EstimatedTotalCell", for: indexPath) as? EstimatedTotalCell {
				cell.balanceLabel.text = amount.normalisedRepresentation
				cell.valueLabel.text = "$0.00"
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
		
		DependencyManager.shared.tzktClient.getAllBalances(forAddress: address) { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data")
				return
			}
			
			self?.account = res
			
			
			// Build arrays of data
			var section1Data: [AnyHashable] = res.tokens
			section1Data.append(res.xtzBalance)
			
			
			// Build snapshot
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections([0, 1])
			
			snapshot.appendItems(section1Data, toSection: 0)
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			
			// Return success
			self?.state = .success(nil)
		}
	}
	
	func viewForHeaderInSection(_ section: Int) -> UIView {
		return UIView()
	}
}
