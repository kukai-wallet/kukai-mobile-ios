//
//  LaunchViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift
import os.log

class LaunchViewController: UIViewController, CAAnimationDelegate {
	
	@IBOutlet weak var kukaiLogo: UIImageView!
	@IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
	@IBOutlet var logoCenterConstraint: NSLayoutConstraint!
	@IBOutlet var logoTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var logoText: UILabel!
	
	private var runOnce = false
	private let hasWallet = DependencyManager.shared.walletList.count > 0
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		if hasWallet {
			logoTopConstraint.isActive = false
			logoCenterConstraint.isActive = true
			
		} else if !runOnce {
			logoTopConstraint.isActive = false
			logoCenterConstraint.isActive = true
			
		} else {
			logoTopConstraint.isActive = true
			logoCenterConstraint.isActive = false
			
			logoWidthConstraint.constant = 200
			logoHeightConstraint.constant = 55
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !runOnce && !hasWallet {
			animate()
			
		} else if hasWallet {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.performSegue(withIdentifier: "home", sender: nil)
			}
			
		} else {
			disolveTransition()
		}
	}
	
	private func animate() {
		logoWidthConstraint.constant = 200
		logoHeightConstraint.constant = 55
		logoTopConstraint.isActive = true
		logoCenterConstraint.isActive = false
		
		UIView.animate(withDuration: 0.6, delay: 0.3) { [weak self] in
			self?.view.layoutIfNeeded()
			
		} completion: { [weak self] success in
			self?.disolveTransition()
		}
	}
	
	private func disolveTransition() {
		self.navigationItem.hidesBackButton = true
		self.navigationItem.largeTitleDisplayMode = .never
		
		runOnce = true
		self.performSegue(withIdentifier: "onboarding", sender: nil)
	}
}
