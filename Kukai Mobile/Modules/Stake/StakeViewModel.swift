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

struct StakeHeaderData: Hashable {
	let title: String
	let actionTitle: String?
}

class StakeViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	private var bag = [AnyCancellable]()
	private var currentSnapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	
	
	// MARK: - Init
	
	override init() {
		super.init()
		
		DependencyManager.shared.$addressRefreshed
			.dropFirst()
			.sink { [weak self] address in
				let selectedAddress = DependencyManager.shared.selectedWalletAddress ?? ""
				if self?.dataSource != nil && selectedAddress == address {
					self?.refresh(animate: true)
				}
			}.store(in: &bag)
	}
	
	deinit {
		bag.forEach({ $0.cancel() })
	}
	
	
	
	// MARK: - Functions
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			
			if let obj = item as? TzKTBaker, let cell = tableView.dequeueReusableCell(withIdentifier: "PublicBakerCell", for: indexPath) as? PublicBakerCell {
				cell.setup(withBaker: obj)
				return cell
				
			} else if let obj = item as? StakeHeaderData, obj.actionTitle != nil, let cell = tableView.dequeueReusableCell(withIdentifier: "StakeHeadingAndActionCell", for: indexPath) as? StakeHeadingCell {
				cell.headingLabel.text = obj.title
				cell.actionTitleLabel?.text = obj.actionTitle
				return cell
				
			} else if let obj = item as? StakeHeaderData, let cell = tableView.dequeueReusableCell(withIdentifier: "StakeHeadingCell", for: indexPath) as? StakeHeadingCell {
				cell.headingLabel.text = obj.title
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
			
			if currentDelegate != nil {
				self?.currentSnapshot.appendSections([0, 1])
				self?.currentSnapshot.appendItems([StakeHeaderData(title: "CURRENT BAKER", actionTitle: nil)], toSection: 0)
				
				if let currentBaker = currentBaker {
					self?.currentSnapshot.appendItems([currentBaker], toSection: 1)
				} else {
					self?.currentSnapshot.appendItems([TzKTBaker(address: currentDelegate?.address ?? "", name: currentDelegate?.alias ?? currentDelegate?.address.truncateTezosAddress(), logo: nil)], toSection: 1)
				}
			}
			
			var nextSectionIndex = 0
			if let count = self?.currentSnapshot.numberOfSections, count != 0 {
				nextSectionIndex = count
			}
			
			self?.currentSnapshot.appendSections(Array(nextSectionIndex..<(filteredResults.count + nextSectionIndex + 1)))
			self?.currentSnapshot.appendItems([StakeHeaderData(title: "SELECT BAKER", actionTitle: "Enter Custom Baker")], toSection: nextSectionIndex)
			nextSectionIndex += 1
			
			for baker in filteredResults {
				self?.currentSnapshot.appendItems([baker], toSection: nextSectionIndex)
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
	
	func setDelegateAndRefresh(toAddress: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard let selectedWallet = DependencyManager.shared.selectedWallet else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find wallet")))
			return
		}
		
		if !state.isLoading() {
			state = .loading
		}
		
		let operations = OperationFactory.delegateOperation(to: toAddress, from: selectedWallet.address)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, walletAddress: selectedWallet.address, base58EncodedPublicKey: selectedWallet.publicKeyBase58encoded()) { estimateResult in
			guard let estimatedOperations = try? estimateResult.get() else {
				completion(Result.failure(estimateResult.getFailure()))
				return
			}
			
			DependencyManager.shared.tezosNodeClient.send(operations: estimatedOperations.operations, withWallet: selectedWallet) { result in
				guard let opHash = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				// Screen will automatically refresh through websocket
				completion(Result.success(opHash))
			}
		}
	}
	
	func bakerFor(indexPath: IndexPath) -> TzKTBaker? {
		return dataSource?.itemIdentifier(for: indexPath) as? TzKTBaker
	}
	
	func isEnterCustom(indePath: IndexPath) -> Bool {
		if let obj = dataSource?.itemIdentifier(for: indePath) as? StakeHeaderData {
			return obj.actionTitle != nil
		}
		
		return false
	}
}
