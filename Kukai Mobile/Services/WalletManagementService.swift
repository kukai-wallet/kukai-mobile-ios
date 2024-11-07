//
//  WalletManagementService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/04/2023.
//

import Foundation
import KukaiCoreSwift
import KukaiCryptoSwift
import Combine
import OSLog

class WalletManagementService {
	
	private static var bag = Set<AnyCancellable>()
	
	/// Cache a new wallet, run tezos domains checks, and update records in DependencyManager correctly
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, backedUp: Bool, markSelected: Bool, completion: @escaping ((String?) -> Void)) {
		let walletCache = WalletCacheService()
		
		do {
			try walletCache.cache(wallet: wallet, childOfIndex: forChildOfIndex, backedUp: backedUp)
			
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
	
	public static func cacheNew(wallet: Wallet, forChildOfIndex: Int?, backedUp: Bool, markSelected: Bool) async -> String? {
		return await withCheckedContinuation({ continuation in
			WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: forChildOfIndex, backedUp: backedUp, markSelected: markSelected) { result in
				continuation.resume(returning: result)
			}
		})
	}
	
	public static func isUsedAccount(address: String, forceMainnet: Bool = true, completion: @escaping ((Bool) -> Void)) {
		DependencyManager.shared.tzktClient.getAccount(forAddress: address, fromURL: forceMainnet ? DependencyManager.defaultTzktURL_mainnet : DependencyManager.shared.currentTzktURL) { result in
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
		if let errorString = await WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, backedUp: true, markSelected: true) {
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
					let _ = await WalletManagementService.cacheNew(wallet: child, forChildOfIndex: hdIndex, backedUp: true, markSelected: false)
				} else {
					isUsedAccount = false
				}
				
				childIndex += 1
			}
			
			return nil
		}
	}
	
	public static func cacheWalletAndScanForAccounts(wallet: LedgerWallet, uuid: String, progress: ((Int) -> Void)? = nil) async -> String? {
		if let errorString = await WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, backedUp: true, markSelected: true) {
			return errorString
			
		} else {
			let hdIndex = DependencyManager.shared.walletList.ledgerWallets.firstIndex(where: { $0.address == wallet.address })
            var usedAccounts: [LedgerWallet] = []
            
            // Level 4
            usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/*'/0'", startIndex: 1, allowedGap: 5, uuid: uuid))
            progress?(usedAccounts.count)
            usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/0'/*'", startIndex: 1, allowedGap: 5, uuid: uuid))
            progress?(usedAccounts.count)
            
            // Level 5
            let acc_0_0_0 = await scanPath("m/44'/1729'/0'/0'/0'", startIndex: 0, allowedGap: 0, uuid: uuid)
            if acc_0_0_0.count > 0 {
                usedAccounts.append(contentsOf: acc_0_0_0)
                progress?(usedAccounts.count)
                usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/*'/0'/0'", startIndex: 1, allowedGap: 5, uuid: uuid))
                progress?(usedAccounts.count)
                usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/0'/*'/0'", startIndex: 1, allowedGap: 5, uuid: uuid))
                progress?(usedAccounts.count)
                usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/0'/0'/*'", startIndex: 1, allowedGap: 5, uuid: uuid))
                progress?(usedAccounts.count)
                
            } else {
                let acc_1_0_0 = await scanPath("m/44'/1729'/1'/0'/0'", startIndex: 0, allowedGap: 0, uuid: uuid)
                let acc_0_1_0 = await scanPath("m/44'/1729'/0'/1'/0'", startIndex: 0, allowedGap: 0, uuid: uuid)
                let acc_0_0_1 = await scanPath("m/44'/1729'/0'/0'/1'", startIndex: 0, allowedGap: 0, uuid: uuid)
                
                if acc_1_0_0.count > 0 {
                    usedAccounts.append(contentsOf: acc_1_0_0)
                    progress?(usedAccounts.count)
                    usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/*'/0'/0'", startIndex: 2, allowedGap: 5, uuid: uuid))
                    progress?(usedAccounts.count)
                }
                if acc_0_1_0.count > 0 {
                    usedAccounts.append(contentsOf: acc_0_1_0)
                    progress?(usedAccounts.count)
                    usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/0'/*'/0'", startIndex: 2, allowedGap: 5, uuid: uuid))
                    progress?(usedAccounts.count)
                }
                if acc_0_0_1.count > 0 {
                    usedAccounts.append(contentsOf: acc_0_0_1)
                    progress?(usedAccounts.count)
                    usedAccounts.append(contentsOf: await scanPath("m/44'/1729'/0'/0'/*'", startIndex: 2, allowedGap: 5, uuid: uuid))
                    progress?(usedAccounts.count)
                }
            }
            
            Logger.app.info("Found \(usedAccounts.count) ledger accounts, caching")
            for child in usedAccounts {
                let _ = await WalletManagementService.cacheNew(wallet: child, forChildOfIndex: hdIndex, backedUp: true, markSelected: false)
            }
            
            return nil
		}
	}
    
    public static func scanPath(_ path: String, startIndex: Int, allowedGap: Int, uuid: String) async -> [LedgerWallet] {
        var gap = 0
        var i = startIndex
        var usedAccounts: [LedgerWallet] = []
        
        while (gap <= allowedGap) {
            let newPath = path.replacingOccurrences(of: "*", with: i.description)
            Logger.app.info("Scanning path: \(newPath)")
            
            let response = await LedgerService.shared.getAddress(forDerivationPath: newPath, verify: false)
            guard let res = try? response.get(),
                  let child = LedgerWallet(address: res.address, publicKey: res.publicKey, derivationPath: newPath, curve: .ed25519, ledgerUUID: uuid) else {
                Logger.app.error("Ledger device returned error contacting the device")
                return usedAccounts
            }
            
            Logger.app.info("Scanning address: \(child.address)")
            if await WalletManagementService.isUsedAccount(address: child.address) {
                usedAccounts.append(child)
                gap = 0
                
            } else {
                gap += 1
            }
            i += 1
        }
        
        return usedAccounts
    }
}
