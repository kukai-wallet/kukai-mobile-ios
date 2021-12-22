//
//  ImportSuccessViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class ImportSuccessViewController: UIViewController {

	@IBOutlet weak var addressLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let address = WalletCacheService().fetchPrimaryWallet()?.address
		addressLabel.text = address
    }
}
