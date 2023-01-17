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
		
		accountDataRefreshedCancellable = DependencyManager.shared.$accountBalancesDidUpdate
			.dropFirst()
			.sink { [weak self] _ in
				if self?.dataSource != nil {
					self?.refresh(animate: true)
				}
			}
		
		AccountViewModel.setupAccountActivityListener()
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
			
			if TokenStateService.shared.moveFavourite(tokenIndex: sourceIndexPath.section-1, toIndex: destinationIndexPath.section-1) {
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				
			} else {
				//self.state = .failure(KukaiError.internalApplicationError(error: "Unable to rearrange favourite"), "Unable to rearrange favourite")
			}
		}
	}
	
	
	
	// MARK: - Functions
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = MoveableDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, item in
			guard let self = self else { return UITableViewCell() }
			
			if let amount = item as? XTZAmount {
				if self.isEditing == false, let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenCell", for: indexPath) as? FavouriteTokenCell {
					cell.tokenIcon.image = UIImage(named: "tezos")?.resizedImage(Size: CGSize(width: 40, height: 40))
					cell.symbolLabel.text = "Tezos"
					cell.balanceLabel.text = amount.normalisedRepresentation
					cell.setFav(true)
					cell.containerView.layer.opacity = 0.5
					
					return cell
				} else if let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenEditCell", for: indexPath) as? FavouriteTokenEditCell {
					cell.tokenIcon.image = UIImage(named: "tezos")?.resizedImage(Size: CGSize(width: 40, height: 40))
					cell.symbolLabel.text = "Tezos"
					cell.balanceLabel.text = amount.normalisedRepresentation
					cell.containerView.layer.opacity = 0.5
					
					return cell
				}
				
			} else if let obj = item as? Token, self.isEditing == false, let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenCell", for: indexPath) as? FavouriteTokenCell {
				
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.tokenIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.tokenIcon.frame.size)
				cell.symbolLabel.text = obj.symbol
				cell.balanceLabel.text = obj.balance.normalisedRepresentation
				cell.setFav(obj.isFavourite)
				
				return cell
				
			} else if let obj = item as? Token, self.isEditing == true, let cell = tableView.dequeueReusableCell(withIdentifier: "FavouriteTokenEditCell", for: indexPath) as? FavouriteTokenEditCell {
				
				MediaProxyService.load(url: obj.thumbnailURL, to: cell.tokenIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: cell.tokenIcon.frame.size)
				cell.symbolLabel.text = obj.symbol
				cell.balanceLabel.text = obj.balance.normalisedRepresentation
				
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
		
		// Group and srot favourites (and remove hidden)
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
		
		tokensToDisplay = tokensToDisplay.sorted(by: { $0.favouriteSortIndex < $1.favouriteSortIndex})
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
	
	func reload(animating: Bool) {
		if let ds = dataSource {
			var snapshot = ds.snapshot()
			snapshot.reloadSections(Array(0..<snapshot.numberOfSections))
			ds.apply(snapshot, animatingDifferences: animating)
		}
	}
	
	func token(atIndexPath: IndexPath) -> Token? {
		return tokensToDisplay[atIndexPath.row]
	}
	
	func handleTap(onTableView: UITableView, atIndexPath: IndexPath) {
		guard atIndexPath.section != 0, let cell = onTableView.cellForRow(at: atIndexPath) as? FavouriteTokenCell else {
			return
		}
		
		let token = tokensToDisplay[atIndexPath.section-1]
		
		if TokenStateService.shared.isFavourite(token: token).isFavourite {
			if TokenStateService.shared.removeFavourite(token: token) {
				cell.setFav(false)
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				favouriteCount -= 1
				
			} else {
				self.state = .failure(KukaiError.internalApplicationError(error: "Unable to remove favourite"), "Unable to remove favourite")
			}
			
		} else {
			if TokenStateService.shared.addFavourite(token: token) {
				cell.setFav(true)
				DependencyManager.shared.balanceService.updateTokenStates()
				DependencyManager.shared.accountBalancesDidUpdate = true
				favouriteCount += 1
				
			} else {
				self.state = .failure(KukaiError.internalApplicationError(error: "Unable to add favourite"), "Unable to add favourite")
			}
		}
	}
	
	func showReorderButton() -> Bool {
		return favouriteCount > 1
	}
}
