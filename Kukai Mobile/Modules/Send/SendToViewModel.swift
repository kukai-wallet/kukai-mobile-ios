//
//  SendToViewModel.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit
import KukaiCoreSwift
import Combine
import OSLog

struct WalletObj: Hashable {
	let icon: UIImage?
	let title: String
	let address: String
}

struct NoContacts: Hashable {
	let id = UUID()
}

class SendToViewModel: ViewModel, UITableViewDiffableDataSourceHandler {
	
	typealias SectionEnum = Int
	typealias CellDataType = AnyHashable
	
	var dataSource: UITableViewDiffableDataSource<Int, AnyHashable>? = nil
	
	private var walletObjs: [WalletObj] = []
	private var bag = Set<AnyCancellable>()
	
	func makeDataSource(withTableView tableView: UITableView) {
		dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
			if let obj = item as? WalletObj, let cell = tableView.dequeueReusableCell(withIdentifier: "AddressChoiceCell", for: indexPath) as? AddressChoiceCell {
				cell.iconView.image = obj.icon
				cell.titleLabel.text = obj.title
				cell.subtitleLabel.text = obj.address
				
				return cell
				
			} else if let _ = item as? NoContacts, let cell = tableView.dequeueReusableCell(withIdentifier: "NoContactsCell", for: indexPath) as? NoContactsCell {
				return cell
				
			} else {
				return UITableViewCell()
			}
		})
		
		dataSource?.defaultRowAnimation = .fade
	}
	
	func refresh(animate: Bool, successMessage: String? = nil) {
		if !state.isLoading() {
			state = .loading
		}
		
		guard let address = DependencyManager.shared.selectedWallet?.address, let ds = dataSource else {
			state = .failure(KukaiError.unknown(withString: "Unable to locate wallet"), "Unable to locate wallet")
			return
		}
		
		// Build arrays of data
		let wallets = WalletCacheService().fetchWallets() ?? []
		walletObjs = []
		
		for wallet in wallets where wallet.address != address {
			if wallet.type == .social {
				let details = imageAndTitleForSocialWallet(wallet: wallet)
				walletObjs.append(WalletObj(icon: details.image, title: details.title, address: wallet.address))
				
			} else if wallet.type == .hd, let hdWallet = wallet as? HDWallet {
				walletObjs.append(WalletObj(icon: UIImage(named: "tz-logo"), title: wallet.address, address: wallet.address))
				for child in hdWallet.childWallets {
					walletObjs.append(WalletObj(icon: UIImage(systemName: "arrow.turn.down.right"), title: child.address, address: child.address))
				}
				
			} else {
				walletObjs.append(WalletObj(icon: UIImage(named: "tz-logo"), title: wallet.address, address: wallet.address))
			}
		}
		
		
		// Build snapshot
		var snapshot = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
		
		if wallets.count > 1 {
			snapshot.appendSections([0, 1])
			snapshot.appendItems([NoContacts()], toSection: 0)
			snapshot.appendItems(walletObjs, toSection: 1)
			
		} else {
			snapshot.appendSections([0])
			snapshot.appendItems([NoContacts()], toSection: 0)
		}
		
		ds.apply(snapshot, animatingDifferences: animate)
		
		state = .success(nil)
	}
	
	func imageAndTitleForSocialWallet(wallet: Wallet) -> (image: UIImage?, title: String) {
		guard let socialWallet = wallet as? TorusWallet else {
			return (image: UIImage(named: "tz-logo"), title: wallet.address)
		}
		
		switch socialWallet.authProvider {
			case .apple:
				return (image: UIImage(named: "social-apple"), title: "Apple account")
				
			case .twitter:
				return (image: UIImage(named: "social-twitter"), title: socialWallet.socialUserId ?? socialWallet.address)
				
			case .google:
				return (image: UIImage(named: "social-google"), title: socialWallet.socialUserId ?? socialWallet.address)
				
			case .reddit:
				return (image: UIImage(named: "tz-logo"), title: socialWallet.socialUsername ?? socialWallet.socialUserId ?? socialWallet.address)
				
			case .facebook:
				return (image: UIImage(named: "tz-logo"), title: socialWallet.socialUsername ?? socialWallet.socialUserId ?? socialWallet.address)
		}
	}
	
	func heightForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> CGFloat {
		let view = viewForHeaderInSection(section, forTableView: tableView)
		view.sizeToFit()
		
		return view.frame.size.height
	}
	
	func viewForHeaderInSection(_ section: Int, forTableView tableView: UITableView) -> UIView {
		
		if section == 0, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell") as? ImageHeadingCell {
			cell.iconView.image = UIImage(named: "contacts")
			cell.iconView.tintColor = .colorNamed("Grey1000")
			cell.headingLabel.text = "Contacts"
			return cell.contentView
			
		} else if section == 1, let cell = tableView.dequeueReusableCell(withIdentifier: "ImageHeadingCell") as? ImageHeadingCell {
			cell.iconView.image = UIImage(named: "wallet")
			cell.iconView.tintColor = .colorNamed("Grey1000")
			cell.headingLabel.text = "My Wallets"
			return cell.contentView
			
		} else {
			return UIView()
		}
	}
	
	func address(forIndexPath indexPath: IndexPath) -> String {
		return walletObjs[indexPath.row].address
	}
	
	func convertStringToAddress(string: String, type: AddressType, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		switch type {
			case .tezosAddress:
				completion(Result.success(string))
				
			case .tezosDomain:
				DependencyManager.shared.tezosDomainsClient.getAddressFor(domain: string).sink { error in
					completion(Result.failure(error))
					
				} onSuccess: { response in
					if let add = response.data?.domain.address {
						completion(Result.success(add))
						
					} else {
						completion(Result.failure(KukaiError.unknown()))
					}
					
				}.store(in: &bag)
				
			case .gmail:
				handleTorus(verifier: .google, string: string, completion: completion)
				
			case .reddit:
				handleTorus(verifier: .reddit, string: string, completion: completion)
				
			case .twitter:
				handleTorus(verifier: .twitter, string: string, completion: completion)
		}
	}
	
	private func handleTorus(verifier: TorusAuthProvider, string: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard DependencyManager.shared.torusVerifiers[verifier] != nil else {
			let error = KukaiError.unknown(withString: "No \(verifier.rawValue) verifier details found")
			completion(Result.failure(error))
			return
		}
		
		DependencyManager.shared.torusAuthService.getAddress(from: verifier, for: string, completion: completion)
	}
}
