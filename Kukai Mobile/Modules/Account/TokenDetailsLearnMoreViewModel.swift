//
//  TokenDetailsLearnMoreViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/11/2024.
//

import UIKit
import KukaiCoreSwift

struct LearnMoreHeaderData: Hashable {
	let id = UUID()
	let title: String
}

struct LearnMoreItemData: Hashable {
	let id = UUID()
	let title: String
	let segueId: String
}

class TokenDetailsLearnMoreViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	
	func makeDataSource(withTableView tableView: UITableView) {
		
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? LearnMoreHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "LearnMoreSectionHeaderCell", for: indexPath) as? LearnMoreSectionHeaderCell {
				cell.titleLabel.text = obj.title
				return cell
				
			} else if let obj = item.base as? LearnMoreItemData, let cell = tableView.dequeueReusableCell(withIdentifier: "LearnMoreItemCell", for: indexPath) as? LearnMoreItemCell {
				cell.titleLabel.text = obj.title
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			state = .failure(KukaiError.internalApplicationError(error: ViewModelError.dataSourceNotCreated), "Unable to process data at this time")
			return
		}
		
		// Build snapshot
		
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		let data: [[AnyHashableSendable]] = [
			[.init(LearnMoreHeaderData(title: "Delegating"))],
			[.init(LearnMoreItemData(title: "What is Delegating?", segueId: "stake-learn-more-1"))],
			[.init(LearnMoreItemData(title: "What is a Baker?", segueId: "stake-learn-more-2"))],
			[.init(LearnMoreItemData(title: "What is Governance?", segueId: "stake-learn-more-3"))],
			[.init(LearnMoreItemData(title: "What is a Cycle?", segueId: "stake-learn-more-4"))],
			[.init(LearnMoreItemData(title: "Are there any risks? (Delegating)", segueId: "stake-learn-more-5"))],
			[.init(LearnMoreItemData(title: "How do I get my rewards? (Delegating)", segueId: "stake-learn-more-6"))],
			
			[.init(LearnMoreHeaderData(title: "Staking"))],
			[.init(LearnMoreItemData(title: "What is Staking?", segueId: "stake-learn-more-7"))],
			[.init(LearnMoreItemData(title: "Are there any risks? (Staking)", segueId: "stake-learn-more-8"))],
			[.init(LearnMoreItemData(title: "How do I get my rewards? (Staking)", segueId: "stake-learn-more-9"))],
			
			[.init(LearnMoreHeaderData(title: "Monitor your Baker"))],
			[.init(LearnMoreItemData(title: "No free space in Baker", segueId: "stake-learn-more-10"))],
			[.init(LearnMoreItemData(title: "Baker not voting", segueId: "stake-learn-more-11"))],
		]
		
		snapshot.appendSections(Array(0..<data.count))
		
		for (index, opt) in data.enumerated() {
			snapshot.appendItems(opt, toSection: index)
		}
		
		ds.applySnapshotUsingReloadData(snapshot)
		
		self.state = .success(nil)
	}
	
	func segue(forIndexPath: IndexPath) -> String? {
		if let obj = dataSource?.itemIdentifier(for: forIndexPath)?.base as? LearnMoreItemData {
			return obj.segueId
		}
		
		return nil
	}
}
