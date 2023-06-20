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
	
	func navigate() {
		var watchMeta = WalletMetadata(address: self.address, hdWalletGroupName: nil, type: .regular, children: [], isChild: false, isWatchOnly: true, bas58EncodedPublicKey: "")
		
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
		
		let walletCache = WalletCacheService()
		if walletCache.cacheWatchWallet(metadata: watchMeta) {
			DependencyManager.shared.walletList = walletCache.readNonsensitive()
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: address)
			self.performSegue(withIdentifier: "done", sender: self)
			
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to cache wallet details")
		}
	}
	
	func findAddressThenNavigate(text: String, type: AddressType) {
		self.showLoadingModal()
		
		enterAddressComponent.findAddress(forText: text) { [weak self] result in
			self?.hideLoadingModal()
			
			guard let res = try? result.get() else {
				self?.hideLoadingModal(completion: {
					self?.alert(errorWithMessage: result.getFailure().description)
				})
				return
			}
			
			self?.address = res.address
			self?.navigate()
		}
	}
}
