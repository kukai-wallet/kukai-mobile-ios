//
//  HiddenTokensMainViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2022.
//

import UIKit

class HiddenTokensMainViewController: UIViewController {

	@IBOutlet weak var segmetnedButton: UISegmentedControl!
	@IBOutlet weak var balancesContainer: UIView!
	@IBOutlet weak var collectiblesContainer: UIView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		segmetnedButton.addUnderlineForSelectedSegment()
		
		let homeTabBar = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count ?? 2)-2] as? HomeTabBarController
		segmetnedButton.selectedSegmentIndex = homeTabBar?.selectedIndex == 0 ? 0 : 1
		segmentedButtonChanged(segmetnedButton as Any)
    }
	
	@IBAction func segmentedButtonChanged(_ sender: Any) {
		segmetnedButton.changeUnderlinePosition()
		
		if segmetnedButton.selectedSegmentIndex == 0 {
			self.balancesContainer.isHidden = false
			self.collectiblesContainer.isHidden = true
			
		} else {
			self.balancesContainer.isHidden = true
			self.collectiblesContainer.isHidden = false
		}
	}
	
	public func openTokenDetails() {
		self.performSegue(withIdentifier: "tokenDetails", sender: nil)
	}
	
	public func openCollectibleDetails() {
		self.performSegue(withIdentifier: "collectibleDetails", sender: nil)
	}
}
