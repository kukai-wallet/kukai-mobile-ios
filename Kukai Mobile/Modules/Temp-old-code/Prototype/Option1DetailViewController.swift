//
//  Option1DetailViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit
import KukaiCoreSwift

/*
public class Option1DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var tableView: UITableView!
	
	private let mediaProxyService = MediaProxyService()
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		
		if PrototypeData.shared.selected == .token {
			let token = DependencyManager.shared.currentAccount?.tokens[PrototypeData.shared.selectedIndex]
			nameLabel.text = token?.name
			symbolLabel.text = token?.symbol
			addressLabel.text = token?.tokenContractAddress
			tableView.isHidden = true
			
		} else {
			let nft = DependencyManager.shared.currentAccount?.nfts[PrototypeData.shared.selectedIndex]
			nameLabel.text = nft?.name
			symbolLabel.text = nft?.symbol
			addressLabel.text = nft?.tokenContractAddress
			tableView.isHidden = false
			tableView.delegate = self
			tableView.dataSource = self
		}
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return DependencyManager.shared.currentAccount?.nfts[PrototypeData.shared.selectedIndex].nfts?.count ?? 0
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Option1Token", for: indexPath) as? Option1TokenCell,
			  let nft = DependencyManager.shared.currentAccount?.nfts[PrototypeData.shared.selectedIndex].nfts?[indexPath.row] else {
			return UITableViewCell()
		}
		
		MediaProxyService.load(url: nft.thumbnailURL, to: cell.tokenIconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: cell.tokenIconView.frame.size)
		cell.titleLabel.text = nft.name
		return cell
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		PrototypeData.shared.selectedNFT = indexPath.row
		self.triggerSegue()
	}
	
	public func triggerSegue() {
		if let selectedNFT = DependencyManager.shared.currentAccount?.nfts[PrototypeData.shared.selectedIndex].nfts?[PrototypeData.shared.selectedNFT] {
			self.showLoadingView(completion: nil)
			
			mediaProxyService.getMediaType(fromFormats: selectedNFT.metadata?.formats ?? [], orURL: selectedNFT.displayURL) { [weak self] result in
				
				DispatchQueue.main.async {
					self?.hideLoadingView(completion: nil)
					
					guard let res = try? result.get() else {
						print("Error: \(result.getFailure())")
						return
					}
					
					if res == .image {
						self?.performSegue(withIdentifier: self?.segueID(fromMedia: "image") ?? "", sender: selectedNFT)
					} else {
						self?.performSegue(withIdentifier: self?.segueID(fromMedia: "video") ?? "", sender: selectedNFT)
					}
				}
			}
		} else {
			print("no NFT found")
		}
	}
	
	func segueID(fromMedia: String) -> String {
		if PrototypeData.shared.selectedOption == 1 {
			return "\(fromMedia)-push"
			
		} else if PrototypeData.shared.selectedOption == 2 {
			return "\(fromMedia)-push"
			
		} else if PrototypeData.shared.selectedOption == 3 {
			return "\(fromMedia)-push"
			
		} else if PrototypeData.shared.selectedOption == 4 {
			return "\(fromMedia)-push"
			
		} else if PrototypeData.shared.selectedOption == 5 {
			return "\(fromMedia)-push"
		}
		
		return "-"
	}
	
	public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let selectedNFT = sender as? NFT else {
			print("can't parse sender as NFT")
			return
		}
		
		if segue.identifier?.contains("video") != nil, let playerController = segue.destination as? DisplayVideoViewController {
			playerController.contentURL = selectedNFT.artifactURL == nil ? selectedNFT.displayURL : selectedNFT.artifactURL
			
		} else if segue.identifier?.contains("image") != nil, let imageController = segue.destination as? DisplayImageViewController, let contentURL = selectedNFT.displayURL {
			imageController.contentURL = contentURL
			
		} else {
			print("Unable to parse NFT data")
		}
	}
}
*/
