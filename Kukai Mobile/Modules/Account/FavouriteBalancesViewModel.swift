//
//  FavouriteBalancesViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class FavouriteBalancesViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	private var accountDataRefreshedCancellable: AnyCancellable?
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	var tokensToDisplay: [Token] = []
	var isEditing = false
	var favouriteCount = 0
	
	
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
	
	class MoveableDiffableDataSource: UITableViewDiffableDataSource<SectionEnum, CellDataType> {
		
		override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
			if indexPath.section == 0 {
				return false
			}
			
			return true
		}
		
		override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
			if indexPath.section == 0 {
				return false
			}
			
			return true
		}
		
		override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
			guard sourceIndexPath.section != destinationIndexPath.section else {
				return
			}
			
			// Record the new state on disk
			if let address = DependencyManager.shared.selectedWalletAddress,
			   let token = (itemIdentifier(for: sourceIndexPath) as? Token),
			   TokenStateService.shared.moveFavouriteBalance(forAddress: address, forToken: token, toIndex: destinationIndexPath.section) {
				
				// We have 1 row per section (to acheive a certain UI). By default, move tries to take a row and move it to another section. We need to modify this to move sections around instead
				// Get the section that its trying to be added too. If its at index 0, then user wants to move source, above destination, so instead assign it to the previous section
				// If index is greater, then user wants it to be below destination section
				var currentSnapshot = self.snapshot()
				if destinationIndexPath.row == 0 {
					// previous section
					currentSnapshot.moveSection(sourceIndexPath.section, beforeSection: destinationIndexPath.section)
					
				} else {
					// next section
					currentSnapshot.moveSection(sourceIndexPath.section, afterSection: destinationIndexPath.section)
				}
				
				self.apply(currentSnapshot)
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				
			} else {
				//self.state = .failure(KukaiError.internalApplicationError(error: "Unable to rearrange favorite"), "Unable to rearrange favorite")
			}
		}
	}
	
	
	
	// MARK: - Functions
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = MoveableDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			
			if let amount = item as? XTZAmount {
				if let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenCell", for: indexPath) as? FavouriteTokenCell {
					cell.tokenIcon.image = UIImage.tezosToken().resizedImage(size: CGSize(width: 40, height: 40))
					cell.symbolLabel.text = "XTZ"
					cell.balanceLabel.text = amount.normalisedRepresentation
					cell.setup(isFav: true, isLocked: true)
					
					if self?.isEditing == true {
						cell.favIconStackview.isHidden = true
						cell.layoutIfNeeded()
					}
					
					return cell
				}
				
			} else if let obj = item as? Token, let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenCell", for: indexPath) as? FavouriteTokenCell {
				
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.tokenIcon, withCacheType: .permanent, fallback: UIImage.unknownToken())
				cell.symbolLabel.text = obj.symbol
				cell.balanceLabel.text = obj.balance.normalisedRepresentation
				cell.setup(isFav: obj.isFavourite, isLocked: false)
				
				return cell
				
			} else if let _ = item as? String, let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyTableViewCell", for: indexPath) as? EmptyTableViewCell {
				return cell
			}
			
			return UITableViewCell()
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		guard let ds = dataSource else {
			return
		}
		
		// Group and sort favourites (and remove hidden)
		tokensToDisplay = []
		var nonFavourites: [Token] = []
		
		for token in DependencyManager.shared.balanceService.account.tokens {
			guard !token.isHidden else {
				continue
			}
			
			if token.isFavourite {
				tokensToDisplay.append(token)
			} else {
				nonFavourites.append(token)
			}
		}
		
		tokensToDisplay = tokensToDisplay.sorted(by: { ($0.favouriteSortIndex ?? tokensToDisplay.count) < ($1.favouriteSortIndex ?? tokensToDisplay.count) })
		favouriteCount = tokensToDisplay.count
		
		// Only add non-favourites if we aren't editing
		if !isEditing {
			tokensToDisplay.append(contentsOf: nonFavourites)
		}
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		snapshot.appendSections(Array(0..<tokensToDisplay.count+1))
		snapshot.appendItems([DependencyManager.shared.balanceService.account.xtzBalance], toSection: 0)
		
		for (index, item) in tokensToDisplay.enumerated() {
			snapshot.appendItems([item], toSection: index+1)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		self.state = .success(nil)
	}
	
	func token(atIndexPath: IndexPath) -> Token? {
		return tokensToDisplay[atIndexPath.row]
	}
	
	func handleTap(onTableView: UITableView, atIndexPath: IndexPath) {
		guard atIndexPath.section != 0, let cell = onTableView.cellForRow(at: atIndexPath) as? FavouriteTokenCell else {
			return
		}
		
		let token = tokensToDisplay[atIndexPath.section-1]
		let address = DependencyManager.shared.selectedWalletAddress ?? ""
		
		if TokenStateService.shared.isFavourite(forAddress: address, token: token) != nil {
			if TokenStateService.shared.removeFavourite(forAddress: address, token: token) {
				cell.setup(isFav: false, isLocked: false)
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				favouriteCount -= 1
				self.refresh(animate: true)
				
			} else {
				self.state = .failure(KukaiError.internalApplicationError(error: "Unable to remove favorite"), "Unable to remove favorite")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(forAddress: address, token: token) {
				cell.setup(isFav: true, isLocked: false)
				DependencyManager.shared.balanceService.updateTokenStates(forAddress: address, selectedAccount: true)
				favouriteCount += 1
				self.refresh(animate: true)
				
			} else {
				self.state = .failure(KukaiError.internalApplicationError(error: "Unable to add favorite"), "Unable to add favorite")
			}
		}
	}
	
	func showReorderButton() -> Bool {
		return favouriteCount > 1
	}
}
