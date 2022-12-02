//
//  SendChooseTokenViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

class SendChooseTokenViewController: UIViewController {
	
	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAlias: UILabel!
	@IBOutlet weak var address: UILabel!
	
	@IBOutlet weak var segmentedButton: UISegmentedControl!
	@IBOutlet weak var balancesContainerView: UIView!
	@IBOutlet weak var collectiblesContainerView: UIView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.view.backgroundColor = UIColor.colorNamed("Grey1900")
		let _ = self.view.addGradientBackgroundFull()
		
		segmentedButton.addUnderlineForSelectedSegment()
		if segmentedButton.selectedSegmentIndex == 0 {
			self.collectiblesContainerView.isHidden = true
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		addressAlias.text = TransactionService.shared.sendData.destinationAlias
		address.text = TransactionService.shared.sendData.destination
	}
	
	@IBAction func segmentedControlChanged(_ sender: Any) {
		if segmentedButton.selectedSegmentIndex == 0 {
			balancesContainerView.isHidden = false
			collectiblesContainerView.isHidden = true
		} else {
			balancesContainerView.isHidden = true
			collectiblesContainerView.isHidden = false
		}
	}
	
	public func tokenChosen() {
		
		if let _ = TransactionService.shared.sendData.chosenToken {
			self.performSegue(withIdentifier: "enter-amount", sender: self)
			
		} else {
			self.performSegue(withIdentifier: "review-send-nft", sender: self)
		}
	}
}
