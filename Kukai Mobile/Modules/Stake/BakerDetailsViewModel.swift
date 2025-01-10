//
//  BakerDetailsViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/12/2024.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct PublicBakerAttributeData: Hashable {
	let id = UUID()
	let title: String
	let value: String
	let valueWarning: Bool
}

class BakerDetailsViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	private var bag = [AnyCancellable]()
	private var currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
	}
	
	deinit {
		cleanup()
	}
	
	func cleanup() {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? ChooseBakerHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseBakerHeadingCell", for: indexPath) as? ChooseBakerHeadingCell {
				cell.headingLabel.text = obj.title
				return cell
				
			} else if let obj = item.base as? PublicBakerAttributeData, let cell = tableView.dequeueReusableCell(withIdentifier: "PublicBakerAttributeCell", for: indexPath) as? PublicBakerAttributeCell {
				cell.setup(data: obj)
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource, let baker = TransactionService.shared.delegateData.chosenBaker else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to find datasource")
			return
		}
		
		// Build snapshot
		self.currentSnapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		
		if baker.delegation.enabled {
			let sectionIndex = self.currentSnapshot.numberOfSections
			self.currentSnapshot.appendSections([ sectionIndex ])
			
			let freeSpace = baker.delegation.freeSpace
			let capacity = baker.delegation.capacity
			let minBalance = baker.delegation.minBalance
			self.currentSnapshot.appendItems([
				.init(ChooseBakerHeaderData(title: "Delegation", actionTitle: nil)),
				.init(PublicBakerAttributeData(title: "Split:", value: (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%", valueWarning: false)),
				.init(PublicBakerAttributeData(title: "Est APY:", value: (Decimal(baker.delegation.estimatedApy) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%", valueWarning: false)),
				.init(PublicBakerAttributeData(title: "Free Space:", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(freeSpace, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: freeSpace < .zero)),
				.init(PublicBakerAttributeData(title: "Capacity:", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(capacity, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: capacity < .zero)),
				.init(PublicBakerAttributeData(title: "Min Balance", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(minBalance, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: minBalance < .zero))
			], toSection: sectionIndex)
		}
		
		if baker.staking.enabled {
			let sectionIndex = self.currentSnapshot.numberOfSections
			self.currentSnapshot.appendSections([ sectionIndex ])
			
			let freeSpace = baker.staking.freeSpace
			let capacity = baker.staking.capacity
			let minBalance = baker.staking.minBalance
			self.currentSnapshot.appendItems([
				.init(ChooseBakerHeaderData(title: "Delegation", actionTitle: nil)),
				.init(PublicBakerAttributeData(title: "Split:", value: (Decimal(baker.staking.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%", valueWarning: false)),
				.init(PublicBakerAttributeData(title: "Est APY:", value: (Decimal(baker.staking.estimatedApy) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%", valueWarning: false)),
				.init(PublicBakerAttributeData(title: "Free Space:", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(freeSpace, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: freeSpace < .zero)),
				.init(PublicBakerAttributeData(title: "Capacity:", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(capacity, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: capacity < .zero)),
				.init(PublicBakerAttributeData(title: "Min Balance", value: DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(minBalance, decimalPlaces: 0, allowNegative: true) + " XTZ", valueWarning: minBalance < .zero))
			], toSection: sectionIndex)
		}
		
		ds.apply(currentSnapshot, animatingDifferences: animate)
		
		// Return success
		self.state = .success(successMessage)
	}
}
