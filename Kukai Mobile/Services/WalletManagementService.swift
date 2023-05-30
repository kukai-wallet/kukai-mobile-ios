//
//  WalletManagementService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/04/2023.
//

import Foundation
import KukaiCoreSwift
import Combine

class WalletManagementService {
	
	/// Cache a new wallet, run tezos domains checks, and update records in DependencyManager correctly
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, markSelected: Bool, completion: @escaping ((Bool) -> Void)) {
		let walletCache = WalletCacheService()
		
		if walletCache.cache(wallet: wallet, childOfIndex: forChildOfIndex) {
			DependencyManager.shared.walletList = walletCache.readNonsensitive()
			
			// Check for existing domains and add to walletMetadata
			DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainFor(address: wallet.address, completion: { result in
				switch result {
					case .success(let response):
						let _ = DependencyManager.shared.walletList.set(mainnetDomain: response.mainnet, ghostnetDomain: response.ghostnet, forAddress: wallet.address)
						let _ = WalletCacheService().writeNonsensitive(DependencyManager.shared.walletList)
						
						if markSelected {
							DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
						}
						
					case .failure(_):
						
						if markSelected {
							// Will fail if none exists, this is a likely occurence and not something the user needs to be aware of
							// Silently move on, it can/will be checked again later in wallet management flow
							DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
						}
				}
				
				completion(true)
			})
			
		} else {
			return completion(false)
		}
	}
	
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, markSelected: Bool) async -> Bool {
		return await withCheckedContinuation({ continuation in
			WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: forChildOfIndex, markSelected: markSelected) { result in
				continuation.resume(returning: result)
			}
		})
	}
	
	public static func isUsedAccount(address: String) async -> Bool {
		return await withCheckedContinuation({ continuation in
			DependencyManager.shared.tzktClient.getAccount(forAddress: address) { result in
				guard let res = try? result.get() else {
					continuation.resume(returning: false)
					return
				}
				
				let result = (res.type == "user" || (res.balance ?? 0) > 0 || (res.tokenBalancesCount ?? 0) > 0)
				continuation.resume(returning: result)
			}
		})
	}
	
	public static func cacheWalletAndScanForAccounts(wallet: HDWallet) async -> Bool {
		guard await WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, markSelected: true),
				let hdIndex = DependencyManager.shared.walletList.hdWallets.firstIndex(where: { $0.address == wallet.address }) else {
			return false
		}
		
		var childIndex = 1
		var isUsedAccount = true
		
		while isUsedAccount {
			guard let child = wallet.createChild(accountIndex: childIndex) else {
				isUsedAccount = false
				continue
			}
			
			if await WalletManagementService.isUsedAccount(address: child.address) {
				let _ = await WalletManagementService.cacheNew(wallet: child, forChildOfIndex: hdIndex, markSelected: false)
			} else {
				isUsedAccount = false
			}
			
			childIndex += 1
		}
		
		return true
	}
}
