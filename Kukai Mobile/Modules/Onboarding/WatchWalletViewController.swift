//
//  WatchWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/06/2023.
//

import UIKit
import KukaiCoreSwift

class WatchWalletViewController: UIViewController, EnterAddressComponentDelegate {

	@IBOutlet weak var enterAddressComponent: EnterAddressComponent!
	
	private var address = ""
	private var alias = ""
	private var type: AddressType = .tezosAddress
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		enterAddressComponent.delegate = self
		enterAddressComponent.updateAvilableAddressTypes([.tezosAddress, .tezosDomain])
		enterAddressComponent.headerLabel.text = "Watch:"
		enterAddressComponent.setAddressTypeHeader("Watch Address")
    }
	
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType) {
		if !validAddress {
			return
		}
		
		self.type = ofType
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			
			if ofType == .tezosAddress {
				self?.address = entered
				self?.navigate()
				
			} else {
				self?.alias = entered
				self?.findAddressThenNavigate(text: entered, type: ofType)
			}
		}
	}
	
	func findAddressThenNavigate(text: String, type: AddressType) {
		self.showLoadingModal()
		
		enterAddressComponent.findAddress(forText: text) { [weak self] result in
			self?.hideLoadingModal()
			
			guard let res = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.windowError(withTitle: "error".localized(), description: result.getFailure().description)
				})
				return
			}
			
			self?.address = res.address
			self?.navigate()
		}
	}
	
	func navigate() {
		var watchMeta = WalletMetadata(address: self.address, hdWalletGroupName: nil, type: .regular, children: [], isChild: false, isWatchOnly: true, bas58EncodedPublicKey: "", backedUp: true)
		
		if self.type == .tezosDomain {
			if DependencyManager.shared.currentNetworkType == .mainnet {
				watchMeta.mainnetDomains = [TezosDomainsReverseRecord(id: "", address: self.address, owner: self.address, expiresAtUtc: nil, domain: TezosDomainsDomain(name: self.alias, address: self.address))]
			} else {
				watchMeta.ghostnetDomains = [TezosDomainsReverseRecord(id: "", address: self.address, owner: self.address, expiresAtUtc: nil, domain: TezosDomainsDomain(name: self.alias, address: self.address))]
			}
		}
		
		if self.type != .tezosDomain && self.type != .tezosAddress {
			
			switch self.type {
				case .gmail:
					watchMeta.socialType = .google
				case .reddit:
					watchMeta.socialType = .reddit
				case .twitter:
					watchMeta.socialType = .twitter
					
				default:
					watchMeta.socialType = .none
			}
			
			watchMeta.socialUsername = self.alias
		}
		
		self.showLoadingView()
		findDomainsAndCache(forMetadata: watchMeta) { [weak self] success in
			self?.hideLoadingView()
			
			if success {
				self?.segue()
			} else {
				self?.enterAddressComponent.textField.text = ""
			}
		}
	}
	
	func findDomainsAndCache(forMetadata metadata: WalletMetadata, completion: @escaping ((Bool) -> Void)) {
		let walletCache = WalletCacheService()
		
		do {
			try walletCache.cacheWatchWallet(metadata: metadata)
			DependencyManager.shared.walletList = walletCache.readMetadataFromDiskAndDecrypt()
			DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainFor(address: metadata.address, completion: { result in
				switch result {
					case .success(let response):
						let _ = DependencyManager.shared.walletList.set(mainnetDomain: response.mainnet, ghostnetDomain: response.ghostnet, forAddress: metadata.address)
						let _ = WalletCacheService().encryptAndWriteMetadataToDisk(DependencyManager.shared.walletList)
						DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: metadata.address)
						
						LookupService.shared.add(displayText: response.mainnet?.domain.name ?? "", forType: .tezosDomain, forAddress: metadata.address, isMainnet: true)
						LookupService.shared.add(displayText: response.ghostnet?.domain.name ?? "", forType: .tezosDomain, forAddress: metadata.address, isMainnet: false)
						LookupService.shared.cacheRecords()
						completion(true)
						
					case .failure(_):
						DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: metadata.address)
						completion(true) // tezos domains failing is not a blocker
				}
			})
			
		} catch let error as WalletCacheError {
			
			if error == WalletCacheError.walletAlreadyExists {
				self.windowError(withTitle: "error".localized(), description: "error-wallet-already-exists".localized())
				completion(false)
			} else {
				self.windowError(withTitle: "error".localized(), description: "error-cant-cache".localized())
				completion(false)
			}
			
		} catch {
			self.windowError(withTitle: "error".localized(), description: "error-cant-cache".localized())
			completion(false)
		}
	}
	
	func segue() {
		let viewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		if let vc = viewController {
			self.navigationController?.popToViewController(vc, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}
