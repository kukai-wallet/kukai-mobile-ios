//
//  Option1ViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit
import Kingfisher
import KukaiCoreSwift

/*
public class Option1MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var tableView: UITableView!
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.dataSource = self
		self.tableView.delegate = self
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if DependencyManager.shared.currentAccount == nil {
			self.showLoadingView(completion: nil)
			
			guard let walletAddress = DependencyManager.shared.selectedWallet?.address else {
				self.alert(errorWithMessage: "Can't find wallet");
				return
			}
			
			DependencyManager.shared.tzktClient.getAllBalances(forAddress: walletAddress) { [weak self] result in
				guard let acc = try? result.get() else {
					self?.hideLoadingView(completion: nil)
					self?.alert(errorWithMessage: "can't get balances, yell at Simon")
					
					print("Error: \(result.getFailure())")
					return
				}
				
				DependencyManager.shared.currentAccount = acc
				self?.tableView.reloadData()
				self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			let maxCount = (DependencyManager.shared.currentAccount?.tokens.count ?? 0) + 1
			if maxCount > 4 {
				return 4
			} else {
				return maxCount
			}
		} else {
			let maxCount = (DependencyManager.shared.currentAccount?.nfts.count ?? 0) + 1
			if maxCount > 4 {
				return 4
			} else {
				return maxCount
			}
		}
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			return tableView.dequeueReusableCell(withIdentifier: "Option1All", for: indexPath)
			
		} else if indexPath.section == 0 {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.tokens[indexPath.row-1] else {
				return UITableViewCell()
			}
			
			MediaProxyService.load(url: token.thumbnailURL, to: cell.tokenIconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconView.frame.size)
			cell.titleLabel.text = "\(token.balance.normalisedRepresentation) \(token.symbol)"
			return cell
			
		} else {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.nfts[indexPath.row-1] else {
				return UITableViewCell()
			}
			
			MediaProxyService.load(url: token.thumbnailURL, to: cell.tokenIconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconView.frame.size)
			cell.titleLabel.text = token.name
			return cell
		}
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == 0 && indexPath.section == 0 {
			PrototypeData.shared.selected = .token
			self.performSegue(withIdentifier: allSegueId(), sender: indexPath)
			
		} else if indexPath.row == 0 && indexPath.section == 1 {
			PrototypeData.shared.selected = .nft
			self.performSegue(withIdentifier: allSegueId(), sender: indexPath)
			
		} else if indexPath.section == 0 {
			PrototypeData.shared.selected = .token
			PrototypeData.shared.selectedIndex = indexPath.row-1
			self.performSegue(withIdentifier: detailSegueID(), sender: indexPath)
			
		} else {
			PrototypeData.shared.selected = .nft
			PrototypeData.shared.selectedIndex = indexPath.row-1
			self.performSegue(withIdentifier: detailSegueID(), sender: indexPath)
		}
	}
	
	public func allSegueId() -> String {
		if PrototypeData.shared.selectedOption == 1 {
			return "all-sheet"
			
		} else if PrototypeData.shared.selectedOption == 2 {
			return "all-push"
			
		} else if PrototypeData.shared.selectedOption == 3 {
			return "all-push"
		}
		
		return ""
	}
	
	public func detailSegueID() -> String {
		if PrototypeData.shared.selectedOption == 1 {
			return "detail-sheet"
			
		} else if PrototypeData.shared.selectedOption == 2 {
			return "detail-push"
			
		} else if PrototypeData.shared.selectedOption == 3 {
			return "detail-sheet"
		}
		
		return ""
	}
}
*/
