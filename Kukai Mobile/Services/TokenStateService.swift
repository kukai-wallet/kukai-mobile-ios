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
	
	private static let hiddenBalancesFilename = "token-state-hidden-balance"
	private static let hiddenCollectiblesFilename = "token-state-hidden-collecitble"
	private static let favouriteBalancesFilename = "token-state-fav-balance"
	private static let favouriteCollectiblesFilename = "token-state-fav-collecitble"
	
	public typealias HiddenType = [String: [String: Bool]]		// { <address>: { "<contract>:<tokenId>": Bool } }
	public typealias FavouriteType = [String: [String: Int]]	// { <address>: { "<contract>:<tokenId>": <sortIndex> } }
	
	public var hiddenBalances: HiddenType = [:]
	public var hiddenCollectibles: HiddenType = [:]
	public var favouriteBalances: FavouriteType = [:]
	public var favouriteCollectibles: FavouriteType = [:]
	
	public static let shared = TokenStateService()
	
	
	
	private init() {
		readAllCaches()
	}
	
	
	
	// MARK: Add
	
	public func addBlankHiddenBalanceIfNeeded(forAddress address: String) {
		if hiddenBalances[address] == nil { hiddenBalances[address] = [:] }
	}
	
	public func addBlankHiddenCollectibleIfNeeded(forAddress address: String) {
		if hiddenCollectibles[address] == nil { hiddenCollectibles[address] = [:] }
	}
	
	public func addBlankFavouriteBalanceIfNeeded(forAddress address: String) {
		if favouriteBalances[address] == nil { favouriteBalances[address] = [:] }
	}
	
	public func addBlankFavouriteCollectibleIfNeeded(forAddress address: String) {
		if favouriteCollectibles[address] == nil { favouriteCollectibles[address] = [:] }
	}
	
	public func addHidden(forAddress address: String, token: Token) -> Bool {
		if !isHidden(forAddress: address, token: token) {
			addBlankHiddenBalanceIfNeeded(forAddress: address)
			hiddenBalances[address]?[balanceId(from: token)] = true
			return writeHiddenBalances()
		}
		
		return false
	}
	
	public func addHidden(forAddress address: String, nft: NFT) -> Bool {
		if !isHidden(forAddress: address, nft: nft) {
			addBlankHiddenCollectibleIfNeeded(forAddress: address)
			hiddenCollectibles[address]?[nftId(from: nft)] = true
			return writeHiddenCollectibles()
		}
		
		return false
	}
	
	public func addFavourite(forAddress address: String, token: Token) -> Bool {
		if isFavourite(forAddress: address, token: token) == nil {
			let count = favouriteBalances[address]?.count ?? -1
			addBlankFavouriteBalanceIfNeeded(forAddress: address)
			favouriteBalances[address]?[balanceId(from: token)] = count + 1
			return writeFavouriteBalances()
		}
		
		return false
	}
	
	public func addFavourite(forAddress address: String, nft: NFT) -> Bool {
		if isFavourite(forAddress: address, nft: nft) == nil {
			let count = favouriteCollectibles[address]?.count ?? -1
			addBlankFavouriteCollectibleIfNeeded(forAddress: address)
			favouriteCollectibles[address]?[nftId(from: nft)] = count + 1
			return writeFavouriteCollectibles()
		}
		
		return false
	}
	
	
	
	// MARK: Helpers
	
	public func balanceId(from token: Token) -> String {
		return (token.tokenContractAddress ?? "") + (token.tokenId ?? 0).description
	}
	
	public func nftId(from nft: NFT) -> String {
		return nft.parentContract + nft.tokenId.description
	}
	
	public func isHidden(forAddress address: String, token: Token) -> Bool {
		return hiddenBalances[address]?[balanceId(from: token)] ?? false
	}
	
	public func isHidden(forAddress address: String, nft: NFT) -> Bool {
		return hiddenCollectibles[address]?[nftId(from: nft)] ?? false
	}
	
	public func isFavourite(forAddress address: String, token: Token) -> Int? {
		return favouriteBalances[address]?[balanceId(from: token)] ?? nil
	}
	
	public func isFavourite(forAddress address: String, nft: NFT) -> Int? {
		return favouriteCollectibles[address]?[nftId(from: nft)] ?? nil
	}
	
	
	
	// MARK: Remove
	
	public func removeHidden(forAddress address: String, token: Token) -> Bool {
		hiddenBalances[address]?.removeValue(forKey: balanceId(from: token))
		return writeHiddenBalances()
	}
	
	public func removeHidden(forAddress address: String, nft: NFT) -> Bool {
		hiddenCollectibles[address]?.removeValue(forKey: nftId(from: nft))
		return writeHiddenCollectibles()
	}
	
	public func removeFavourite(forAddress address: String, token: Token) -> Bool {
		let balanceId = balanceId(from: token)
		let currentSortIndex = favouriteBalances[address]?[balanceId] ?? -1
		reduceSortIndex(afterIndex: currentSortIndex, inDict: &favouriteBalances, withAddress: address)
		
		favouriteBalances[address]?.removeValue(forKey: balanceId)
		return writeFavouriteBalances()
	}
	
	public func removeFavourite(forAddress address: String, nft: NFT) -> Bool {
		let balanceId = nftId(from: nft)
		let currentSortIndex = favouriteCollectibles[address]?[balanceId] ?? -1
		reduceSortIndex(afterIndex: currentSortIndex, inDict: &favouriteCollectibles, withAddress: address)
		
		favouriteCollectibles[address]?.removeValue(forKey: nftId(from: nft))
		return writeFavouriteCollectibles()
	}
	
	
	
	// MARK: Reorder
	
	public func moveFavouriteBalance(forAddress address: String, forToken token: Token, toIndex: Int) -> Bool {
		let balanceId = balanceId(from: token)
		let currentSortIndex = favouriteBalances[address]?[balanceId] ?? -1
		
		if currentSortIndex < toIndex {
			// moving down, decrease others
			reduceSortIndex(afterIndex: currentSortIndex, inDict: &favouriteBalances, withAddress: address)
		} else {
			// moving up, increase others
			increaseSortIndex(beforeIndex: currentSortIndex, inDict: &favouriteBalances, withAddress: address)
		}
		
		favouriteBalances[address]?[balanceId] = toIndex
		return writeFavouriteBalances()
	}
	
	public func moveFavouriteCollectible(forAddress address: String, forNft nft: NFT, toIndex: Int) -> Bool {
		let balanceId = nftId(from: nft)
		let currentSortIndex = favouriteCollectibles[address]?[balanceId] ?? -1
		
		if currentSortIndex < toIndex {
			// moving down, decrease others
			reduceSortIndex(afterIndex: currentSortIndex, inDict: &favouriteCollectibles, withAddress: address)
		} else {
			// moving up, increase others
			increaseSortIndex(beforeIndex: currentSortIndex, inDict: &favouriteCollectibles, withAddress: address)
		}
		
		favouriteCollectibles[address]?[balanceId] = toIndex
		return writeFavouriteCollectibles()
	}
	
	
	// MARK: Private funcs
	
	private func readAllCaches() {
		self.hiddenBalances = DiskService.read(type: HiddenType.self, fromFileName: TokenStateService.hiddenBalancesFilename) ?? [:]
		self.hiddenCollectibles = DiskService.read(type: HiddenType.self, fromFileName: TokenStateService.hiddenCollectiblesFilename) ?? [:]
		self.favouriteBalances = DiskService.read(type: FavouriteType.self, fromFileName: TokenStateService.favouriteBalancesFilename) ?? [:]
		self.favouriteCollectibles = DiskService.read(type: FavouriteType.self, fromFileName: TokenStateService.favouriteCollectiblesFilename) ?? [:]
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
	
	private func reduceSortIndex(afterIndex: Int, inDict dict: inout [String: [String: Int]], withAddress address: String) {
		var tempDict: [String: Int] = (dict[address] ?? [:])
		
		for key in tempDict.keys {
			if let val = tempDict[key], val > afterIndex {
				tempDict[key] = val-1
			}
		}
		
		dict[address] = tempDict
	}
	
	private func increaseSortIndex(beforeIndex: Int, inDict dict: inout [String: [String: Int]], withAddress address: String) {
		var tempDict: [String: Int] = (dict[address] ?? [:])
		
		for key in tempDict.keys {
			if let val = tempDict[key], val < beforeIndex {
				tempDict[key] = val+1
			}
		}
		
		dict[address] = tempDict
	}
	
	
	
	// MARK: Delete
	
	public func deleteAllCaches() {
		let _ = DiskService.delete(fileName: TokenStateService.hiddenBalancesFilename)
		let _ = DiskService.delete(fileName: TokenStateService.hiddenCollectiblesFilename)
		let _ = DiskService.delete(fileName: TokenStateService.favouriteBalancesFilename)
		let _ = DiskService.delete(fileName: TokenStateService.favouriteCollectiblesFilename)
	}
}
