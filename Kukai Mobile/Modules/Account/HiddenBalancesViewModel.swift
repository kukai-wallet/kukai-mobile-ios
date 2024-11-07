//
//  HiddenBalancesViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class HiddenBalancesViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	var tokensToDisplay: [Token] = []
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		accountDataRefreshedCancellable = DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}
	}
	
	deinit {
		accountDataRefreshedCancellable?.cancel()
	}
	
	
	
	// MARK: - Functions
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item.base as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "HiddenTokenCell", for: indexPath) as? HiddenTokenCell {
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.tokenIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
				cell.symbolLabel.text = obj.symbol
				cell.balanceLabel.text = obj.balance.normalisedRepresentation
				
				return cell
				
			} else if let _ = item.base as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyTableViewCell", for: indexPath) as? EmptyTableViewCell {
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		tokensToDisplay = DependencyManager.shared.balanceService.account.tokens.filter({ $0.isHidden })
		var section1Data: [AnyHashableSendable] = tokensToDisplay.map({ .init($0) })
		
		
		if section1Data.count == 0 {
			section1Data = [.init("")]
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0])
		snapshot.appendItems(section1Data, toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func token(atIndexPath: IndexPath) -> Token? {
		if let token = dataSource?.itemIdentifier(for: atIndexPath)?.base as? Token {
			return token
		}
		
		return nil
	}
}
