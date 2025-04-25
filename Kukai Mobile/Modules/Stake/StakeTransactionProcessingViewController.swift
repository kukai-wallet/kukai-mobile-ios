//
//  StakeTransactionProcessingViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/04/2025.
//

import UIKit
import Combine

class StakeTransactionProcessingViewController: UIViewController {
	
	@IBInspectable var isStaking: Bool = false
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var checkImage: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var continueText: UILabel?
	
	private var bag = [AnyCancellable]()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		checkImage.isHidden = true
		activityIndicator.startAnimating()
		continueText?.isHidden = true
		
		DependencyManager.shared.activityService.$addressesWithPendingOperation
			.dropFirst()
			.sink { [weak self] addresses in
				guard let address = DependencyManager.shared.selectedWalletAddress else {
					return
				}
				
				if !addresses.contains([address]) {
					DispatchQueue.main.async { [weak self] in
						self?.transactionProcessed()
					}
				}
			}.store(in: &bag)
    }
	
	public func transactionProcessed() {
		
		if isStaking {
			titleLabel.text = "Staking complete"
			
		} else {
			titleLabel.text = "Success, you are delegating!"
		}
		
		activityIndicator.stopAnimating()
		activityIndicator.isHidden = true
		checkImage.isHidden = false
		continueText?.isHidden = false
	}
}
