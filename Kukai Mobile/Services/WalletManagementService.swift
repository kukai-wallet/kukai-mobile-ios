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
	
	private static var bag = Set<AnyCancellable>()
	
	/// Cache a new wallet, run tezos domains checks, and update records in DependencyManager correctly
	public static func cacheNew(wallet: Wallet, forChildIndex: Int?, completion: @escaping ((Bool) -> Void)) {
		let walletCache = WalletCacheService()
		
		if walletCache.cache(wallet: wallet, childOfIndex: forChildIndex) {
			DependencyManager.shared.walletList = walletCache.readNonsensitive()
			
			// Check for existing domains and add to walletMetadata
			DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainFor(address: wallet.address)
				.sink(onError: { error in
					
					// Will fail if none exists, this is a likely occurence and not something the user needs to be aware of
					// Silently move on, it can/will be checked again later in wallet management flow
					DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
					completion(true)
					WalletManagementService.bag.removeAll()
					
				}, onSuccess: { resultTuple in
					
					let mainnetRes = resultTuple.mainnet?.data?.reverseRecord
					let ghostnetRes = resultTuple.ghostnet?.data?.reverseRecord
					let _ = DependencyManager.shared.walletList.set(mainnetDomain: mainnetRes, ghostnetDomain: ghostnetRes, forAddress: wallet.address)
					let _ = WalletCacheService().writeNonsensitive(DependencyManager.shared.walletList)
					DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
					completion(true)
					WalletManagementService.bag.removeAll()
				})
				.store(in: &WalletManagementService.bag)
			
		} else {
			return completion(false)
		}
	}
}
