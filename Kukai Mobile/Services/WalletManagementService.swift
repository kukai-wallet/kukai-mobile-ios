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
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, markSelected: Bool, completion: @escaping ((String?) -> Void)) {
		let walletCache = WalletCacheService()
		
		do {
			try walletCache.cache(wallet: wallet, childOfIndex: forChildOfIndex, backedUp: true)
			
			DependencyManager.shared.walletList = walletCache.readMetadataFromDiskAndDecrypt()
			if wallet.type == .social, let tWallet = wallet as? TorusWallet {
				
				var lookupType: LookupType = .address
				switch tWallet.authProvider {
					case .google:
						lookupType = .google
						
					case .reddit:
						lookupType = .reddit
						
					case .twitter:
						lookupType = .twitter
						
					default:
						lookupType = .address
				}
				
				if lookupType == .google {
					LookupService.shared.add(displayText: tWallet.socialUserId ?? "", forType: lookupType, forAddress: wallet.address, isMainnet: true)
					LookupService.shared.add(displayText: tWallet.socialUserId ?? "", forType: lookupType, forAddress: wallet.address, isMainnet: false)
					
				} else if lookupType != .address {
					LookupService.shared.add(displayText: tWallet.socialUsername ?? "", forType: lookupType, forAddress: wallet.address, isMainnet: true)
					LookupService.shared.add(displayText: tWallet.socialUsername ?? "", forType: lookupType, forAddress: wallet.address, isMainnet: false)
				}
			}
			
			
			// Check for existing domains and add to walletMetadata
			DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainFor(address: wallet.address, completion: { result in
				switch result {
					case .success(let response):
						let _ = DependencyManager.shared.walletList.set(mainnetDomain: response.mainnet, ghostnetDomain: response.ghostnet, forAddress: wallet.address)
						let _ = WalletCacheService().encryptAndWriteMetadataToDisk(DependencyManager.shared.walletList)
						
						LookupService.shared.add(displayText: response.mainnet?.domain.name ?? "", forType: .tezosDomain, forAddress: wallet.address, isMainnet: true)
						LookupService.shared.add(displayText: response.ghostnet?.domain.name ?? "", forType: .tezosDomain, forAddress: wallet.address, isMainnet: false)
						
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
				
				LookupService.shared.cacheRecords()
				completion(nil)
				return
			})
			
		} catch let error as WalletCacheError {
			
			if error == WalletCacheError.walletAlreadyExists {
				completion("error-wallet-already-exists".localized())
			} else {
				completion( String.localized(String.localized("error-cant-cache-cause"), withArguments: error.rawValue) )
			}
			
		} catch {
			completion( String.localized(String.localized("error-cant-cache-cause"), withArguments: error.localizedDescription) )
		}
	}
	
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, markSelected: Bool) async -> String? {
		return await withCheckedContinuation({ continuation in
			WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: forChildOfIndex, markSelected: markSelected) { result in
				continuation.resume(returning: result)
			}
		})
	}
	
	public static func isUsedAccount(address: String, completion: @escaping ((Bool) -> Void)) {
		DependencyManager.shared.tzktClient.getAccount(forAddress: address) { result in
			guard let res = try? result.get() else {
				completion(false)
				return
			}
			
			let result = (res.type == "user" || (res.balance ?? 0) > 0 || (res.tokenBalancesCount ?? 0) > 0)
			completion(result)
		}
	}
	
	public static func isUsedAccount(address: String) async -> Bool {
		return await withCheckedContinuation({ continuation in
			WalletManagementService.isUsedAccount(address: address) { result in
				continuation.resume(returning: result)
			}
		})
	}
	
	public static func cacheWalletAndScanForAccounts(wallet: HDWallet, progress: ((Int) -> Void)? = nil) async -> String? {
		if let errorString = await WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, markSelected: true) {
			return errorString
			
		} else {
			let hdIndex = DependencyManager.shared.walletList.hdWallets.firstIndex(where: { $0.address == wallet.address })
			var childIndex = 1
			var isUsedAccount = true
			
			while isUsedAccount {
				guard let child = wallet.createChild(accountIndex: childIndex) else {
					isUsedAccount = false
					continue
				}
				
				if await WalletManagementService.isUsedAccount(address: child.address) {
					progress?(childIndex)
					let _ = await WalletManagementService.cacheNew(wallet: child, forChildOfIndex: hdIndex, markSelected: false)
				} else {
					isUsedAccount = false
				}
				
				childIndex += 1
			}
			
			return nil
		}
	}
}
