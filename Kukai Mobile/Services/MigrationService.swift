//
//  MigrationService.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/05/2024.
//

import Foundation
import KukaiCoreSwift

class MigrationService {
	
	private static let userDefaultsVersionKey = "com.kukai.previous-version-check"
	
	// Do not run this inside applicationDidLaunchWithOptions, due to prewarming issue with fileprotection
	public static func runChecks() {
		let currentBuildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
		let currentBuildInt = Int(currentBuildString) ?? 0
		
		let previousBuildString = UserDefaults.standard.string(forKey: MigrationService.userDefaultsVersionKey) ?? "0"
		let previousBuildInt = Int(previousBuildString) ?? 0
		
		if currentBuildInt == previousBuildInt { return }
		
		/*
		 // Only leaving here as a sample for future record of how to use this setup. Can be removed once a new usecase is added
		if previousBuildInt < 296 {
			markSocialWalletsAsNotBackedUp()
		}
		*/
		
		UserDefaults.standard.set(currentBuildString, forKey: MigrationService.userDefaultsVersionKey)
	}
	
	/*
	private static func markSocialWalletsAsNotBackedUp() {
		guard StorageService.didCompleteOnboarding(), DependencyManager.shared.walletList.socialWallets.count > 0 else { return }
		
		let walletCache = WalletCacheService()
		for meta in DependencyManager.shared.walletList.socialWallets {
			var metadata = meta
			metadata.backedUp = false
			
			let _ = DependencyManager.shared.walletList.update(address: metadata.address, with: metadata)
		}
		
		let _ = walletCache.encryptAndWriteMetadataToDisk(DependencyManager.shared.walletList)
		DependencyManager.shared.walletList = walletCache.readMetadataFromDiskAndDecrypt()
		
		if let address = DependencyManager.shared.selectedWalletAddress {
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: address)
		}
	}
	*/
}
