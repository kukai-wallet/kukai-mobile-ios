//
//  StakeViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/09/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

class StakeViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			let sectionIdentifier = self?.dataSource?.sectionIdentifier(for: indexPath.section)
			
			if sectionIdentifier == 0, let obj = item as? TzKTBaker, let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentBakerCell", for: indexPath) as? CurrentBakerCell {
				if let logo = obj.logo, let url = URL(string: logo) {
					MediaProxyService.load(url: url, to: cell.bakerIcon, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.bakerIcon.frame.size)
				}
				
				cell.bakerNameLabel.text = obj.name ?? obj.address
				cell.splitLabel.text = (obj.fee * 100).description + "%"
				cell.spaceLabel.text = obj.stakingCapacity.rounded(scale: 6, roundingMode: .down).description + " tez"
				cell.estRewardsLabel.text = (obj.estimatedRoi * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
				
				return cell
				
			} else if sectionIdentifier == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "EnterAddressCell", for: indexPath) as? EnterAddressCell {
				return cell
				
			} else if sectionIdentifier == 2, let obj = item as? TzKTBaker, let cell = tableView.dequeueReusableCell(withIdentifier: "PublicBakerCell", for: indexPath) as? PublicBakerCell {
				if let logo = obj.logo, let url = URL(string: logo) {
					MediaProxyService.load(url: url, to: cell.bakerIcon, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.bakerIcon.frame.size)
				}
				
				cell.bakerNameLabel.text = obj.name ?? obj.address
				cell.splitLabel.text = (obj.fee * 100).description + "%"
				cell.spaceLabel.text = obj.stakingCapacity.rounded(scale: 6, roundingMode: .down).description + " tez"
				cell.estRewardsLabel.text = (obj.estimatedRoi * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
				
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let xtzBalanceAsDecimal = DependencyManager.shared.balanceService.account.xtzBalance.toNormalisedDecimal() else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		let currentDelegate = DependencyManager.shared.balanceService.account.delegate
		var currentBaker: TzKTBaker? = nil
		
		DependencyManager.shared.tzktClient.bakers { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to fetch bakers, please try again"), "Unable to fetch bakers, please try again")
				return
			}
			
			var filteredResults = res.filter { baker in
				if baker.address == currentDelegate?.address {
					currentBaker = baker
					return false
				}
				
				return baker.stakingCapacity > xtzBalanceAsDecimal && baker.openForDelegation && baker.serviceHealth != .dead
			}
			
			filteredResults.sort { lhs, rhs in
				lhs.estimatedRoi > rhs.estimatedRoi
			}
			
			
			// Build snapshot
			self?.currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
			
			if let currentDelegate = currentDelegate {
				self?.currentSnapshot.appendSections([0, 1, 2])
				
				// If we found the current baker, attach it, if not create a fake baker object from the bits of data we have from the delegate
				if let currentBaker = currentBaker {
					self?.currentSnapshot.appendItems([currentBaker], toSection: 0)
				} else {
					self?.currentSnapshot.appendItems([TzKTBaker(address: currentDelegate.address, name: currentDelegate.alias, logo: nil)], toSection: 0)
				}
				
			} else {
				self?.currentSnapshot.appendSections([1, 2])
			}
			
			// Regardless, add the enter baker widget and the list of backers to section 1, and 2
			self?.currentSnapshot.appendItems([""], toSection: 1)
			self?.currentSnapshot.appendItems(filteredResults, toSection: 2)
			
			guard let snapshot = self?.currentSnapshot else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to apply snapshot"), "Unable to apply snapshot")
				return
			}
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			
			// Return success
			self?.state = .success(nil)
		}
	}
}
