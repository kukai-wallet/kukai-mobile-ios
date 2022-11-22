//
//  TokenStateService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import Foundation
import KukaiCoreSwift

/// Managing and persisting states like hidden, favourite, watchlist etc for tokens/collectibles/defi-pools
public class TokenStateService {
	
	public struct TokenStateItem: Codable, Hashable {
		let address: String
		let id: Decimal?
	}
	
	private static let hiddenBalancesFilename = "token-state-hidden-balance"
	private static let hiddenCollectiblesFilename = "token-state-hidden-collecitble"
	private static let favouriteBalancesFilename = "token-state-fav-balance"
	private static let favouriteCollectiblesFilename = "token-state-fav-collecitble"
	
	public static let shared = TokenStateService()
	
	public var hiddenBalances: [TokenStateItem] = []
	public var hiddenCollectibles: [TokenStateItem] = []
	public var favouriteBalances: [TokenStateItem] = []
	public var favouriteCollectibles: [TokenStateItem] = []
	
	private init() {
		//DiskService.delete(fileName: TokenStateService.hiddenBalancesFilename)
		readAllCaches()
	}
	
	
	
	// MARK: Add
	
	public func addHidden(token: Token) -> Bool {
		if !isHidden(token: token) {
			hiddenBalances.append(stateItem(fromToken: token))
			return writeHiddenBalances()
		}
		
		return false
	}
	
	public func addHidden(nft: NFT) -> Bool {
		if !isHidden(nft: nft) {
			hiddenCollectibles.append(stateItem(fromCollectible: nft))
			return writeHiddenCollectibles()
		}
		
		return false
	}
	
	public func addFavourite(token: Token) -> Bool {
		if !isFavourite(token: token).isFavourite {
			favouriteBalances.append(stateItem(fromToken: token))
			return writeFavouriteBalances()
		}
		
		return false
	}
	
	public func addFavourite(nft: NFT) -> Bool {
		if !isFavourite(nft: nft) {
			favouriteCollectibles.append(stateItem(fromCollectible: nft))
			return writeFavouriteCollectibles()
		}
		
		return false
	}
	
	
	
	// MARK: Helpers
	
	public func isHidden(token: Token) -> Bool {
		return hiddenBalances.contains { item in
			return item.address == token.tokenContractAddress && item.id == token.tokenId
		}
	}
	
	public func isHidden(nft: NFT) -> Bool {
		return hiddenCollectibles.contains { item in
			item.address == nft.parentContract && item.id == nft.tokenId
		}
	}
	
	public func isFavourite(token: Token) -> (isFavourite: Bool, sortIndex: Int) {
		let stateItem = stateItem(fromToken: token)
		if let index = favouriteBalances.firstIndex(of: stateItem) {
			return (isFavourite: true, sortIndex: index)
		}
		
		return (isFavourite: false, sortIndex: 0)
	}
	
	public func isFavourite(nft: NFT) -> Bool {
		return favouriteCollectibles.contains { item in
			item.address == nft.parentContract && item.id == nft.tokenId
		}
	}
	
	public func stateItem(fromToken token: Token) -> TokenStateItem {
		return TokenStateItem(address: token.tokenContractAddress ?? "", id: token.tokenId)
	}
	
	public func stateItem(fromCollectible nft: NFT) -> TokenStateItem {
		return TokenStateItem(address: nft.parentContract, id: nft.tokenId)
	}
	
	
	
	// MARK: Remove
	
	public func removeHidden(token: Token) -> Bool {
		let stateItem = stateItem(fromToken: token)
		if let index = hiddenBalances.firstIndex(of: stateItem) {
			hiddenBalances.remove(at: index)
			return writeHiddenBalances()
		}
		
		return false
	}
	
	public func removeHidden(nft: NFT) -> Bool {
		let stateItem = stateItem(fromCollectible: nft)
		if let index = hiddenCollectibles.firstIndex(of: stateItem) {
			hiddenCollectibles.remove(at: index)
			return writeHiddenCollectibles()
		}
		
		return false
	}
	
	public func removeFavourite(token: Token) -> Bool {
		let stateItem = stateItem(fromToken: token)
		if let index = favouriteBalances.firstIndex(of: stateItem) {
			favouriteBalances.remove(at: index)
			return writeFavouriteBalances()
		}
		
		return false
	}
	
	public func removeFavourite(nft: NFT) -> Bool {
		let stateItem = stateItem(fromCollectible: nft)
		if let index = favouriteCollectibles.firstIndex(of: stateItem) {
			favouriteCollectibles.remove(at: index)
			return writeFavouriteCollectibles()
		}
		
		return false
	}
	
	
	
	// MARK: Re-order
	
	public func moveFavourite(tokenIndex fromIndex: Int, toIndex: Int) -> Bool {
		favouriteBalances.move(fromOffsets: IndexSet([fromIndex]), toOffset: toIndex)
		return writeFavouriteBalances()
	}
	
	
	
	// MARK: Private funcs
	
	private func readAllCaches() {
		self.hiddenBalances = DiskService.read(type: [TokenStateItem].self, fromFileName: TokenStateService.hiddenBalancesFilename) ?? []
		self.hiddenCollectibles = DiskService.read(type: [TokenStateItem].self, fromFileName: TokenStateService.hiddenCollectiblesFilename) ?? []
		self.favouriteBalances = DiskService.read(type: [TokenStateItem].self, fromFileName: TokenStateService.favouriteBalancesFilename) ?? []
		self.favouriteCollectibles = DiskService.read(type: [TokenStateItem].self, fromFileName: TokenStateService.favouriteCollectiblesFilename) ?? []
	}
	
	private func writeHiddenBalances() -> Bool {
		return DiskService.write(encodable: hiddenBalances, toFileName: TokenStateService.hiddenBalancesFilename)
	}
	
	private func writeHiddenCollectibles() -> Bool  {
		return DiskService.write(encodable: hiddenCollectibles, toFileName: TokenStateService.hiddenCollectiblesFilename)
	}
	
	private func writeFavouriteBalances() -> Bool  {
		return DiskService.write(encodable: favouriteBalances, toFileName: TokenStateService.favouriteBalancesFilename)
	}
	
	private func writeFavouriteCollectibles() -> Bool  {
		return DiskService.write(encodable: favouriteCollectibles, toFileName: TokenStateService.favouriteCollectiblesFilename)
	}
}
