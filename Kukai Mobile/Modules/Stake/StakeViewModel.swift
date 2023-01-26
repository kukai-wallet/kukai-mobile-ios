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
	private var bag = Set<AnyCancellable>()
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var sectionHeaders = ["CURRENT BAKER", "ENTER NEW BAKER ADDRESS", "OR, CHOOSE A PUBLIC BAKER"]
	var infoDelegate: PublicBakerCellInfoDelegate? = nil
	
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
				cell.baker = obj
				cell.infoDelegate = self?.infoDelegate
				
				return cell
				
			} else if sectionIdentifier == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "EnterAddressCell", for: indexPath) as? EnterAddressCell {
				cell.enterAddressComponent.delegate = self
				
				return cell
				
			} else if sectionIdentifier == 2, let obj = item as? TzKTBaker, let cell = tableView.dequeueReusableCell(withIdentifier: "PublicBakerCell", for: indexPath) as? PublicBakerCell {
				if let logo = obj.logo, let url = URL(string: logo) {
					MediaProxyService.load(url: url, to: cell.bakerIcon, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.bakerIcon.frame.size)
				}
				
				cell.bakerNameLabel.text = obj.name ?? obj.address
				cell.splitLabel.text = (obj.fee * 100).description + "%"
				cell.spaceLabel.text = obj.stakingCapacity.rounded(scale: 6, roundingMode: .down).description + " tez"
				cell.estRewardsLabel.text = (obj.estimatedRoi * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
				cell.baker = obj
				cell.stakeDelegate = self
				cell.infoDelegate = self?.infoDelegate
				
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
			self?.state = .success(successMessage)
		}
	}
	
	func heightForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> CGFloat {
		let view = viewForHeaderInSection(section, forTableView: tableView)
		view.sizeToFit()
		
		return view.frame.size.height
	}
	
	func viewForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> UIView {
		if let cell = tableView.dequeueReusableCell(withIdentifier: "StakeHeadingCell") as? StakeHeadingCell {
			cell.headingLabel.text = sectionHeaders[section]
			return cell.contentView
			
		} else {
			return UIView()
		}
	}
	
	func convertStringToAddress(string: String, type: AddressType, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		switch type {
			case .tezosAddress:
				completion(Result.success(string))
				
			case .tezosDomain:
				DependencyManager.shared.tezosDomainsClient.getAddressFor(domain: string).sink { error in
					completion(Result.failure(error))
					
				} onSuccess: { response in
					if let add = response.data?.domain.address {
						completion(Result.success(add))
						
					} else {
						completion(Result.failure(KukaiError.unknown()))
					}
					
				}.store(in: &bag)
				
			case .gmail:
				handleTorus(verifier: .google, string: string, completion: completion)
				
			case .reddit:
				handleTorus(verifier: .reddit, string: string, completion: completion)
				
			case .twitter:
				handleTorus(verifier: .twitter, string: string, completion: completion)
		}
	}
	
	private func handleTorus(verifier: TorusAuthProvider, string: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard DependencyManager.shared.torusVerifiers[verifier] != nil else {
			let error = KukaiError.unknown(withString: "No \(verifier.rawValue) verifier details found")
			completion(Result.failure(error))
			return
		}
		
		DependencyManager.shared.torusAuthService.getAddress(from: verifier, for: string, completion: completion)
	}
	
	func setDelegateAndRefresh(toAddress: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		/*guard let selectedWallet = DependencyManager.shared.selectedWallet else {
			completion(Result.failure(KukaiError.unknown(withString: "Can't find wallet")))
			return
		}
		
		let operations = OperationFactory.delegateOperation(to: toAddress, from: selectedWallet.address)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: selectedWallet) { estimateResult in
			guard let estimatedOperations = try? estimateResult.get() else {
				completion(Result.failure(estimateResult.getFailure()))
				return
			}
			
			DependencyManager.shared.tezosNodeClient.send(operations: estimatedOperations, withWallet: selectedWallet) { result in
				guard let opHash = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: selectedWallet.address, refreshType: .refreshAccountOnly) { error in
					if let e = error {
						completion(Result.failure(e))
					} else {
						completion(Result.success(opHash))
					}
				}
			}
		}*/
	}
}

extension StakeViewModel: EnterAddressComponentDelegate {
	
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType) {
		if !validAddress {
			return
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			self?.state = .loading
			
			if ofType == .tezosAddress {
				
				self?.setDelegateAndRefresh(toAddress: entered) { [weak self] result in
					guard let res = try? result.get() else {
						self?.state = .failure(result.getFailure(), "Error setting Delegate, pelase try again")
						return
					}
					
					self?.state = .success("Baker change successful, opHash = \(res)")
				}
				
			} else {
				self?.convertStringToAddress(string: entered, type: ofType) { [weak self] result in
					guard let res = try? result.get() else {
						self?.state = .failure(result.getFailure(), "Unable to get TZ address from input, please check and try again")
						return
					}
					
					self?.setDelegateAndRefresh(toAddress: res) { [weak self] result in
						guard let res = try? result.get() else {
							self?.state = .failure(result.getFailure(), "Error setting Delegate, pelase try again")
							return
						}
						
						self?.state = .success("Baker change successful, opHash = \(res)")
					}
				}
			}
		}
	}
}

extension StakeViewModel: PublicBakerCellStakeDelegate {
	
	func stakeButtonTapped(forBaker: TzKTBaker?) {
		guard let baker = forBaker else {
			state = .failure(KukaiError.unknown(), "Error setting Delegate, pelase try again")
			return
		}
		
		state = .loading
		setDelegateAndRefresh(toAddress: baker.address) { [weak self] result in
			guard let res = try? result.get() else {
				self?.state = .failure(result.getFailure(), "Error setting Delegate, pelase try again")
				return
			}
			
			self?.state = .success("New Delegate set, operation hash = \(res)")
		}
	}
}
