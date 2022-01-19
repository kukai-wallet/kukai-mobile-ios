//
//  Option1DetailViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit

public class Option1DetailViewController: UIViewController {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		
		
		if PrototypeData.shared.selected == .token {
			let token = DependencyManager.shared.currentAccount?.tokens[PrototypeData.shared.selectedIndex]
			nameLabel.text = token?.name
			symbolLabel.text = token?.symbol
			addressLabel.text = token?.tokenContractAddress
			
		} else {
			let nft = DependencyManager.shared.currentAccount?.nfts[PrototypeData.shared.selectedIndex]
			nameLabel.text = nft?.name
			symbolLabel.text = nft?.symbol
			addressLabel.text = nft?.tokenContractAddress
		}
	}
}
