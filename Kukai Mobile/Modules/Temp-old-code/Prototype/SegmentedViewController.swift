//
//  SegmentedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit
import KukaiCoreSwift

/*
public class SegmentedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var xtzBalanceLabel: UILabel!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
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
					return
				}
				
				DependencyManager.shared.currentAccount = acc
				self?.tableView.reloadData()
				self?.hideLoadingView(completion: nil)
			}
		}
	}
	
	@IBAction func segmentedTapped(_ sender: Any) {
		self.tableView.reloadData()
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		self.addressLabel.text = DependencyManager.shared.selectedWallet?.address
		self.xtzBalanceLabel.text = (DependencyManager.shared.currentAccount?.xtzBalance.normalisedRepresentation ?? "") + " XTZ"
		
		return 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if segmentedControl.selectedSegmentIndex == 0 {
			return DependencyManager.shared.currentAccount?.tokens.count ?? 0
			
		} else if segmentedControl.selectedSegmentIndex == 1 {
			return DependencyManager.shared.currentAccount?.nfts.count ?? 0
			
		} else {
			return 0
		}
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if segmentedControl.selectedSegmentIndex == 0 {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.tokens[indexPath.row] else {
				return UITableViewCell()
			}
			
			MediaProxyService.load(url: token.thumbnailURL, to: cell.tokenIconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconView.frame.size)
			cell.titleLabel.text = "\(token.balance.normalisedRepresentation) \(token.symbol)"
			return cell
			
		} else if segmentedControl.selectedSegmentIndex == 1 {
			guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell, let token = DependencyManager.shared.currentAccount?.nfts[indexPath.row] else {
				return UITableViewCell()
			}
			
			MediaProxyService.load(url: token.thumbnailURL, to: cell.tokenIconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconView.frame.size)
			cell.titleLabel.text = token.name
			return cell
			
		} else {
			return UITableViewCell()
		}
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if segmentedControl.selectedSegmentIndex == 0 {
			PrototypeData.shared.selected = .token
			
		} else if segmentedControl.selectedSegmentIndex == 1 {
			PrototypeData.shared.selected = .nft
			
		} else {
			PrototypeData.shared.selected = .token
		}
		
		PrototypeData.shared.selectedIndex = indexPath.row
		self.performSegue(withIdentifier: detailSegueID(), sender: indexPath)
	}
	
	public func detailSegueID() -> String {
		if PrototypeData.shared.selectedOption == 4 {
			return "detail-sheet"
			
		} else if PrototypeData.shared.selectedOption == 5 {
			return "detail-push"
			
		}
		
		return ""
	}
}
*/
