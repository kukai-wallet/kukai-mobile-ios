//
//  HiddenCollectiblesViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/12/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class HiddenCollectiblesViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashableSendable
	
	var dataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType>? = nil
	var collectiblesToDisplay: [NFT] = []
	
	
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
			
			if let obj = item.base as? NFT, let cell = tableView.dequeueReusableCell(withIdentifier: "HiddenTokenCell", for: indexPath) as? HiddenTokenCell {
				let url = MediaProxyService.url(fromUri: obj.thumbnailURI, ofFormat: MediaProxyService.Format.small.rawFormat())
				MediaProxyService.load(url: url, to: cell.tokenIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
				cell.symbolLabel.text = obj.name
				cell.balanceLabel.text = obj.parentAlias ?? obj.parentContract.truncateTezosAddress()
				
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
		
		
		collectiblesToDisplay = []
		for nftGroup in DependencyManager.shared.balanceService.account.nfts {
			collectiblesToDisplay.append(contentsOf: (nftGroup.nfts ?? []).filter({ $0.isHidden }))
		}
		
		var section1Data: [AnyHashable] = collectiblesToDisplay
		
		if section1Data.count == 0 {
			section1Data = [""]
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<SectionEnum, CellDataType>()
		snapshot.appendSections([0])
		snapshot.appendItems(section1Data.map({ .init($0) }), toSection: 0)
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func nft(atIndexPath: IndexPath) -> NFT? {
		if let nft = dataSource?.itemIdentifier(for: atIndexPath)?.base as? NFT {
			return nft
		}
		
		return nil
	}
}
