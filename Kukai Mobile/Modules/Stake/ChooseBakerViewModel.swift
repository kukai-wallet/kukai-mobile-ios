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

struct ChooseBakerHeaderData: Hashable {
	let title: String
	let actionTitle: String?
}

class ChooseBakerViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	private var bag = [AnyCancellable]()
	private var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	var bakers: [TzKTBaker] = []
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? TzKTBaker, let cell = tableView.dequeueReusableCell(withIdentifier: "PublicBakerCell", for: indexPath) as? PublicBakerCell {
				cell.setup(withBaker: obj)
				return cell
				
			} else if let obj = item.base as? ChooseBakerHeaderData, obj.actionTitle != nil, let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseBakerHeadingAndActionCell", for: indexPath) as? ChooseBakerHeadingCell {
				cell.headingLabel.text = obj.title
				cell.actionTitleLabel?.text = obj.actionTitle
				return cell
				
			} else if let obj = item.base as? ChooseBakerHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseBakerHeadingCell", for: indexPath) as? ChooseBakerHeadingCell {
				cell.headingLabel.text = obj.title
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let xtzAvailableBalance = DependencyManager.shared.balanceService.account.availableBalance.toNormalisedDecimal() else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		if !state.isLoading() {
			state = .loading
		}
		
		let currentDelegate = DependencyManager.shared.balanceService.account.delegate
		var currentBaker: TzKTBaker? = nil
		
		DependencyManager.shared.tzktClient.bakers { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to fetch bakers, please try again"), "Unable to fetch bakers, please try again")
				return
			}
			
			self?.bakers = res
			let filteredResults = res.filter { baker in
				if baker.address == currentDelegate?.address {
					currentBaker = baker
					return false
				}
				
				return baker.delegation.capacity > xtzAvailableBalance && baker.staking.capacity > xtzAvailableBalance && baker.status == TzKTBakerStatus.active
			}
			
			let sortedResults = filteredResults.sorted(by: { lhs, rhs in
				lhs.staking.estimatedApy > rhs.staking.estimatedApy
			})
			
			
			// Build snapshot
			self?.currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
			
			if currentDelegate != nil {
				self?.currentSnapshot.appendSections([0, 1])
				self?.currentSnapshot.appendItems([.init(ChooseBakerHeaderData(title: "CURRENT BAKER", actionTitle: nil))], toSection: 0)
				
				if let currentBaker = currentBaker {
					self?.currentSnapshot.appendItems([.init(currentBaker)], toSection: 1)
				} else {
					self?.currentSnapshot.appendItems([.init(TzKTBaker(address: currentDelegate?.address ?? "", name: currentDelegate?.alias ?? currentDelegate?.address.truncateTezosAddress()))], toSection: 1)
				}
			}
			
			var nextSectionIndex = 0
			if let count = self?.currentSnapshot.numberOfSections, count != 0 {
				nextSectionIndex = count
			}
			
			self?.currentSnapshot.appendSections(Array(nextSectionIndex..<(sortedResults.count + nextSectionIndex + 1)))
			self?.currentSnapshot.appendItems([.init(ChooseBakerHeaderData(title: "SELECT BAKER", actionTitle: "Enter Custom Baker"))], toSection: nextSectionIndex)
			nextSectionIndex += 1
			
			for baker in sortedResults {
				self?.currentSnapshot.appendItems([.init(baker)], toSection: nextSectionIndex)
				nextSectionIndex += 1
			}
			
			guard let snapshot = self?.currentSnapshot else {
				self?.state = .failure(KukaiError.unknown(withString: "Unable to apply snapshot"), "Unable to apply snapshot")
				return
			}
			
			ds.apply(snapshot, animatingDifferences: animate)
			
			
			// Return success
			self?.state = .success(successMessage)
		}
	}
	
	func bakerFor(indexPath: IndexPath) -> TzKTBaker? {
		return dataSource?.itemIdentifier(for: indexPath)?.base as? TzKTBaker
	}
	
	func bakerFor(address: String) -> TzKTBaker? {
		return bakers.first(where: { $0.address == address })
	}
	
	func isEnterCustom(indexPath: IndexPath) -> Bool {
		if let obj = dataSource?.itemIdentifier(for: indexPath)?.base as? ChooseBakerHeaderData {
			return obj.actionTitle != nil
		}
		
		return false
	}
}
