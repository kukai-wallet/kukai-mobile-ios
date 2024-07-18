//
//  CreateWithSocialViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit
import KukaiCoreSwift
import CustomAuth

class CreateWithSocialViewController: UIViewController {
	
	@IBOutlet var scrollView: AutoScrollView!
	@IBOutlet var topSectionContainer: UIView!
	@IBOutlet var learnMoreButton: CustomisableButton!
	@IBOutlet var appleButton: CustomisableButton!
	@IBOutlet var googleButton: CustomisableButton!
	
	@IBOutlet var socialOptions1: UIStackView!
	@IBOutlet var facebookButton: CustomisableButton!
	@IBOutlet var twitterButton: CustomisableButton!
	@IBOutlet var redditButton: CustomisableButton!
	
	@IBOutlet var continueWIthEmailButton: CustomisableButton!
	
	private let cloudKitService = CloudKitService()
	private var appleGradient = CAGradientLayer()
	private var googleGradient = CAGradientLayer()
	private var torusObserver: NSObjectProtocol?
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		appleButton.customButtonType = .primary
		appleButton.configuration?.imagePadding = 8
		googleButton.customButtonType = .tertiary
		googleButton.configuration?.imagePadding = 8
		continueWIthEmailButton.customButtonType = .secondary
		
		facebookButton.customButtonType = .secondary
		twitterButton.customButtonType = .secondary
		redditButton.customButtonType = .secondary
		
		learnMoreButton.configuration?.imagePlacement = .trailing
		learnMoreButton.configuration?.imagePadding = 8
		
		
		// Can't detect certain events from Torus presented modals (e.g. when a user clicks cancel). Adding a second listener to the notification they use so I can trigger a loading modal
		let torusNotificationName: Notification.Name = .init("TSDSDKCallbackNotification")
		self.torusObserver = CustomAuth.notificationCenter.addObserver(forName: torusNotificationName, object: nil, queue: OperationQueue.main) { [weak self] notification in
			self?.showLoadingView()
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.scrollView.setupAutoScroll(focusView: continueWIthEmailButton, parentView: self.view)
		self.scrollView.autoScrollDelegate = self
		
		
		// Check to see if we need to fetch torus verfier config
		if DependencyManager.shared.torusVerifiers.keys.count == 0 {
			self.showLoadingView()
			
			cloudKitService.fetchConfigItems { [weak self] error in
				self?.hideLoadingView()
				
				if let e = error {
					self?.windowError(withTitle: "error".localized(), description: String.localized(String.localized("error-no-cloudkit-config"), withArguments: e.localizedDescription))
					self?.navigationController?.popViewController(animated: true)
					
				} else {
					let response = self?.cloudKitService.extractTorusConfig()
					
					DependencyManager.shared.torusVerifiers = response?.verifiers ?? [:]
					DependencyManager.shared.torusMainnetKeys = response?.mainnetKeys ?? [:]
					DependencyManager.shared.torusTestnetKeys = response?.testnetKeys ?? [:]
					DependencyManager.shared.setupTorus()
				}
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.scrollView.stopAutoScroll()
		self.torusObserver = nil
	}
	
	@IBAction func appleTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.apple] != nil else {
			self.windowError(withTitle: "error".localized(), description: "error-missing-verifier".localized())
			return
		}
		
		self.showLoadingView() // uses different callback structure to rest, need to pop loading here
		DependencyManager.shared.torusAuthService.createWallet(from: .apple, displayOver: self.presentedViewController) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		createWallet(withVerifier: .google)
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		createWallet(withVerifier: .facebook)
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		createWallet(withVerifier: .twitter)
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		createWallet(withVerifier: .reddit)
	}
	
	@IBAction func continueWithEmailTapped(_ sender: Any) {
		createWallet(withVerifier: .email)
	}
	
	private func createWallet(withVerifier verifier: TorusAuthProvider) {
		guard DependencyManager.shared.torusVerifiers[verifier] != nil else {
			self.windowError(withTitle: "error".localized(), description: "error-missing-verifier".localized())
			return
		}
		
		DependencyManager.shared.torusAuthService.createWallet(from: verifier, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	func handleResult(result: Result<TorusWallet, KukaiError>) {
		switch result {
			case .success(let wallet):
				self.updateLoadingModalStatusLabel(message: "Wallet created, checking for tezos domain registrations")
				
				WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, backedUp: false, markSelected: true) { [weak self] errorString in
					if let eString = errorString {
						self?.hideLoadingView()
						self?.windowError(withTitle: "error".localized(), description: eString)
					} else {
						self?.navigate()
					}
				}
				
			case .failure(let error):
				self.hideLoadingView()
				
				// Cancelled errors
				if (error.subType?.domain != "com.apple.AuthenticationServices.AuthorizationError" && error.subType?.code != 1001) &&
					!(error.errorType == .internalApplication && error.subType?.code == 1)
				{
					self.windowError(withTitle: "error".localized(), description: error.description)
				}
		}
	}
	
	private func navigate() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
			self?.hideLoadingView()
			let viewController = self?.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
			if let vc = viewController {
				self?.navigationController?.popToViewController(vc, animated: true)
				AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			} else {
				self?.performSegue(withIdentifier: "done", sender: nil)
			}
		}
	}
}

extension CreateWithSocialViewController: AutoScrollViewDelegate {
	
	func keyboardWillShow() {
		self.topSectionContainer.alpha = 0.2
		self.topSectionContainer.isUserInteractionEnabled = false
	}
	
	func keyboardWillHide() {
		self.topSectionContainer.alpha = 1
		self.topSectionContainer.isUserInteractionEnabled = true
	}
}
