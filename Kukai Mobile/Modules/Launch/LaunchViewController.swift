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
	private var hasWallet = DependencyManager.shared.walletList.count() > 0
	private let cloudKitService = CloudKitService()
	private var dispatchGroup = DispatchGroup()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		dispatchGroup = DispatchGroup()
		dispatchGroup.enter() // cloud config to download
		dispatchGroup.enter() // animation to finish
		
		// Check to see if we need to fetch torus verfier config
		if DependencyManager.shared.torusVerifiers.keys.count == 0 {
			cloudKitService.fetchConfigItems { [weak self] error in
				if let e = error {
					self?.alert(errorWithMessage: "Unable to fetch config settings: \(e)")
					
				} else {
					DependencyManager.shared.torusVerifiers = self?.cloudKitService.extractTorusConfig() ?? [:]
				}
				
				self?.dispatchGroup.leave()
			}
		} else {
			self.dispatchGroup.leave()
		}
		
		// When everything done, perform transition
		dispatchGroup.notify(queue: .main) { [weak self] in
			self?.transition()
		}
		
		
		
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
		
		hasWallet = DependencyManager.shared.walletList.count() > 0
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !runOnce && !hasWallet {
			animate()
			
		} else if !runOnce && hasWallet {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.dispatchGroup.leave()
			}
		} else {
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
				self?.transition()
			}
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
			self?.dispatchGroup.leave()
		}
	}
	
	private func transition() {
		self.navigationItem.hidesBackButton = true
		self.navigationItem.largeTitleDisplayMode = .never
		
		runOnce = true
		let didCompleteOnboarding = SecureLoginService.didCompleteOnboarding()
		
		if hasWallet && didCompleteOnboarding {
			self.performSegue(withIdentifier: "home", sender: nil)
			
		} else if hasWallet && !didCompleteOnboarding {
			let _ = WalletCacheService().deleteAllCacheAndKeys()
			self.performSegue(withIdentifier: "onboarding", sender: nil)
			
		} else {
			self.performSegue(withIdentifier: "onboarding", sender: nil)
		}
	}
}
