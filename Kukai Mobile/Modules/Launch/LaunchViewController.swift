//
//  LaunchViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift
import Sentry
import os.log

import Combine

class LaunchViewController: UIViewController, CAAnimationDelegate {
	
	@IBOutlet weak var kukaiLogo: UIImageView!
	@IBOutlet weak var logoWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
	@IBOutlet var logoCenterConstraint: NSLayoutConstraint!
	@IBOutlet var logoTopConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var logoText: UILabel!
	
	private var runOnce = false
	private var hasWallet = DependencyManager.shared.walletList.count() > 0
	private var dispatchGroup = DispatchGroup()
	
	//var bag1: AnyCancellable? = nil
	//var bag2: AnyCancellable? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		/*
		bag1 = DependencyManager.shared.balanceService.$addressRefreshed.dropFirst().sink(receiveValue: { address in
			
		})
		
		bag2 = DependencyManager.shared.balanceService.$addressesWaitingToBeRefreshed.dropFirst().sink(receiveValue: { addresses in
			
		})
		
		
		DependencyManager.shared.balanceService.fetch(records: [
			BalanceService.FetchRequestRecord(address: "1", type: .refreshAccountOnly),
			BalanceService.FetchRequestRecord(address: "2", type: .refreshAccountOnly),
			BalanceService.FetchRequestRecord(address: "3", type: .refreshAccountOnly)
		])
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
			DependencyManager.shared.balanceService.fetch(records: [
				BalanceService.FetchRequestRecord(address: "4", type: .refreshAccountOnly),
				BalanceService.FetchRequestRecord(address: "5", type: .refreshAccountOnly),
				BalanceService.FetchRequestRecord(address: "6", type: .refreshAccountOnly)
			])
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
			DependencyManager.shared.balanceService.fetch(records: [
				BalanceService.FetchRequestRecord(address: "7", type: .refreshAccountOnly),
				BalanceService.FetchRequestRecord(address: "8", type: .refreshAccountOnly),
				BalanceService.FetchRequestRecord(address: "9", type: .refreshAccountOnly)
			])
		}
		*/
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		hasWallet = DependencyManager.shared.walletList.count() > 0
		
		dispatchGroup = DispatchGroup()
		dispatchGroup.enter() // animation to finish
		
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
		// For safety reasons, ensure this code can't run during prewarming/while disk protection is active
		if StorageService.isPrewarming() { return }
		
		self.navigationItem.hidesBackButton = true
		self.navigationItem.largeTitleDisplayMode = .never
		
		runOnce = true
		//let didCompleteOnboarding = StorageService.didCompleteOnboarding()
		
		if hasWallet && /*didCompleteOnboarding &&*/ !StorageService.isPasscodeNil()  {
			if let sceneDelgate = (self.view.window?.windowScene?.delegate as? SceneDelegate) {
				sceneDelgate.showPrivacyProtectionWindow()
				self.performSegue(withIdentifier: "home", sender: nil)
			}
			
		} /*else if hasWallet && !didCompleteOnboarding {
			SentrySDK.capture(message: "Reinstall cache clear - hasWallet & notOnboarded")
			let _ = WalletCacheService().deleteAllCacheAndKeys()
			StorageService.deleteKeychainItems()
			self.performSegue(withIdentifier: "onboarding", sender: nil)
			
		}*/ else if hasWallet && StorageService.isPasscodeNil() {
			SentrySDK.capture(message: "Reinstall cache clear - hasWallet & passcodeNil")
			let _ = WalletCacheService().deleteAllCacheAndKeys()
			StorageService.deleteKeychainItems()
			self.performSegue(withIdentifier: "onboarding", sender: nil)
			
		} else {
			if hasWallet {
				SentrySDK.capture(message: "Reinstall cache clear - unknown")
			}
			let _ = WalletCacheService().deleteAllCacheAndKeys()
			StorageService.deleteKeychainItems()
			self.performSegue(withIdentifier: "onboarding", sender: nil)
		}
	}
}
