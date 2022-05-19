//
//  DebugViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/05/2022.
//

import UIKit
import KukaiCoreSwift

class DebugViewController: UITableViewController {
	
	private var titles = ["Generate report", "Cache obliterator"]
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return titles.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
		cell.textLabel?.text = titles[indexPath.row]
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if indexPath.row == 0 {
			generateReport()
			
		} else if indexPath.row == 1 {
			obliterateCache()
		}
	}
	
	private func generateReport() {
		var report = "State / Useful information: \n\n"
		
		let walletCacheService = WalletCacheService()
		let wallets = walletCacheService.fetchWallets()
		
		report += "Network: \n"
		report += "Current Network type: \n" + DependencyManager.shared.currentNetworkType.rawValue + " \n\n"
		report += "Current Node URL: \n" + DependencyManager.shared.currentNodeURL.absoluteString + " \n\n"
		report += "Current Chain name: \n" + DependencyManager.shared.tezosChainName.rawValue + " \n\n"
		report += "Current TzKT URL: \n" + DependencyManager.shared.currentTzktURL.absoluteString + " \n\n"
		report += "Current BCD URL: \n" + DependencyManager.shared.currentBcdURL.absoluteString + " \n\n"
		report += "Current Tezos Domains URL: \n" + DependencyManager.shared.currentTezosDomainsURL.absoluteString + " \n\n"
		
		report += "\n\n\nWallet: \n"
		report += "Selected Wallet index parent: \n" + "\(DependencyManager.shared.selectedWalletIndex.parent)" + " \n\n"
		report += "Selected Wallet index child: \n" + "\(DependencyManager.shared.selectedWalletIndex.child ?? -1)" + " \n\n"
		report += "Selected Wallet address: \n" + (DependencyManager.shared.selectedWallet?.address ?? "-None-") + " \n\n"
		report += "Total wallet count: \n" + "\(wallets?.count ?? 0)" + " \n\n"
		
		report += "\n\n\nBalances: \n"
		report += "Has fetched initial data: \n" + "\(DependencyManager.shared.balanceService.hasFetchedInitialData)" + " \n\n"
		report += "Has currency changed: \n" + "\(DependencyManager.shared.balanceService.currencyChanged)" + " \n\n"
		report += "Wallet address to fetch: \n" + "\(DependencyManager.shared.balanceService.account.walletAddress)" + " \n\n"
		report += "XTZ Balance: \n" + "\(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation)" + " \n\n"
		report += "Baker address: \n" + "\(DependencyManager.shared.balanceService.account.bakerAddress ?? "-None-")" + " \n\n"
		report += "Number of unique tokens: \n" + "\(DependencyManager.shared.balanceService.account.tokens.count)" + " \n\n"
		report += "Number of unique NFT groups: \n" + "\(DependencyManager.shared.balanceService.account.nfts.count)" + " \n\n"
		report += "Number of Dex token pairs: \n" + "\(DependencyManager.shared.balanceService.exchangeData.count)" + " \n\n"
		report += "Number of Dex exchange rate pairs cached: \n" + "\(DependencyManager.shared.balanceService.tokenValueAndRate.keys.count)" + " \n\n"
		report += "Estimated total XTZ: \n" + "\(DependencyManager.shared.balanceService.estimatedTotalXtz.normalisedRepresentation)" + " \n\n"
		
		
		self.alert(withTitle: "Report ready", andMessage: "Report ready, tap 'Ok' to copy report to clipboard, otherwise click cancel") { action in
			UIPasteboard.general.string = report
			
		} cancelAction: { action in
			// do nothing
		}
	}
	
	private func obliterateCache() {
		self.alert(withTitle: "Really?", andMessage: "Clicking ok will attempt to delete everything stored by this app and return to the start. Are you sure?") { action in
			BeaconService.shared.stopBeacon { [weak self] beaconStopped in
				DispatchQueue.main.async {
					DependencyManager.shared.tzktClient.stopListeningForAccountChanges()
					
					let _ = WalletCacheService().deleteCacheAndKeys()
					self?.clearDocumentsDirectory()
					TransactionService.shared.resetState()
					
					let domain = Bundle.main.bundleIdentifier ?? "app.kukai.mobile"
					UserDefaults.standard.removePersistentDomain(forName: domain)
					
					DependencyManager.shared.setDefaultMainnetURLs(supressUpdateNotification: true)
					
					self?.navigationController?.popToRootViewController(animated: true)
				}
			}
			
		} cancelAction: { action in
			// do nothing
		}
	}
	
	private func clearDocumentsDirectory() {
		guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return
		}
		
		do {
			let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
			for fileURL in fileURLs {
				try FileManager.default.removeItem(at: fileURL)
			}
		} catch  {
			print("Error: \(error)")
		}
	}
}
