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
	var heading: String = ""
	
	
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
	
	
	// AssetsTotalCell
	// AssetsChartCell
	// AssetsBuyTezCell
	// AssetsTokenTezCell
	// AssetsTokenCell
	
	
	
	// MARK: - Functions
	
	private class DiffableTableViewWithSectionHeaders: UITableViewDiffableDataSource<Int, AnyHashable> {
		override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
			if section == 0 {
				return "Total Balance"
				
			} else if section == 1 {
				return "Your Assets"
				
			} else {
				return ""
			}
		}
	}
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if indexPath.section == 0 {
				if indexPath.row == 0, let title = item as? String {
					let cell = tableView.dequeueReusableCell(withIdentifier: "AssetsSectionHeaderCell", for: indexPath) as? AssetsSectionHeaderCell
					cell?.titleLabel.text = title
					return cell
				}
				if indexPath.row == 1, let xtzBalance = item as? XTZAmount {
					let cell = tableView.dequeueReusableCell(withIdentifier: "AssetsTotalCell", for: indexPath) as? AssetsTotalCell
					cell?.tezLabel.text = xtzBalance.normalisedRepresentation + " tez"
					cell?.fiatLabel.text = "$0.00"
					return cell
					
				} else if indexPath.row == 2 {
					return tableView.dequeueReusableCell(withIdentifier: "AssetsChartCell", for: indexPath)
					
				} else {
					return tableView.dequeueReusableCell(withIdentifier: "AssetsBuyTezCell", for: indexPath)
				}
				
			} else if indexPath.section == 1, let title = item as? String {
				let cell = tableView.dequeueReusableCell(withIdentifier: "AssetsSectionHeaderCell", for: indexPath) as? AssetsSectionHeaderCell
				cell?.titleLabel.text = title
				return cell
				
			} else if indexPath.section == 2, let token = item as? String {
				let cell = tableView.dequeueReusableCell(withIdentifier: "AssetsTokenTezCell", for: indexPath) as? AssetsTokenCell
				cell?.iconView.image = UIImage(named: "tezos-xtz-logo")
				cell?.tokenLabel.text = token
				cell?.conversionLabel.text = "$0.00"
				return cell
				
			} else {
				guard let token = item as? Token else {
					print("Couldn't cast \(item) as Token")
					return UITableViewCell()
				}
				
				let cell = tableView.dequeueReusableCell(withIdentifier: "AssetsTokenCell", for: indexPath) as? AssetsTokenCell
				cell?.iconView.setKuakiImage(withURL: token.thumbnailURL, downSampleStandardImage: (width: 30, height: 30))
				cell?.tokenLabel.text = token.balance.normalisedRepresentation
				cell?.symbolLabel?.text = token.symbol
				cell?.conversionLabel.text = "$0.00"
				return cell
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
		
		
		/*
		guard let ac = DependencyManager.shared.betterCallDevClient.cachedAccountInfo() else {
			state = .failure(ErrorResponse.error(string: "", errorType: .unknownWallet), "Unable to fetch data")
			return
		}
		
		self.account = ac
		self.heading = address
		
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections([0, 1, 2, 3])
		
		snapshot.appendItems(["Total Balance", ac.xtzBalance, "chart", "buyTez"], toSection: 0)
		snapshot.appendItems(["Your Assets"], toSection: 1)
		snapshot.appendItems([ac.xtzBalance.normalisedRepresentation + " tez"], toSection: 2)
		snapshot.appendItems(ac.tokens, toSection: 3)
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		self.state = .success(nil)
		*/
		
		DependencyManager.shared.betterCallDevClient.fetchAccountInfo(forAddress: address) { [weak self] result in
			guard let acc = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Unable to fetch data. Please check internet connection and try again")
				return
			}
			
			self?.account = acc
			self?.heading = address
			
			var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			snapshot.appendSections([0, 1, 2, 3])
			
			snapshot.appendItems(["Total Balance", acc.xtzBalance, "chart", "buyTez"], toSection: 0)
			snapshot.appendItems(["Your Assets"], toSection: 1)
			snapshot.appendItems([acc.xtzBalance.normalisedRepresentation + " tez"], toSection: 2)
			snapshot.appendItems(acc.tokens, toSection: 3)
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			self?.state = .success(nil)
		}
	}
}
