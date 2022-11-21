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
		
		segmetnedButton.addUnderlineForSelectedSegment()
		if segmetnedButton.selectedSegmentIndex == 0 {
			self.collectiblesContainer.isHidden = true
		}
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
}
