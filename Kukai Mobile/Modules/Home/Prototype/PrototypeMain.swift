//
//  PrototypeMain.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/01/2022.
//

import UIKit
import KukaiCoreSwift

public class PrototypeMain: UIViewController {
	
	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		PrototypeData.shared.reset()
	}
	
	@IBAction func option1(_ sender: Any) {
		PrototypeData.shared.selectedOption = 1
		self.performSegue(withIdentifier: "allvertical", sender: self)
	}
	
	@IBAction func option2(_ sender: Any) {
		PrototypeData.shared.selectedOption = 2
		self.performSegue(withIdentifier: "allvertical", sender: self)
	}
	
	@IBAction func option3(_ sender: Any) {
		PrototypeData.shared.selectedOption = 3
		self.performSegue(withIdentifier: "allvertical", sender: self)
	}
	
	@IBAction func deleteWallet(_ sender: Any) {
		let _ = WalletCacheService().deleteCacheAndKeys()
		self.navigationController?.popToRootViewController(animated: true)
	}
}
