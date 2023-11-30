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
	
	@IBOutlet var socialOptions2: UIStackView!
	@IBOutlet var discordButton: CustomisableButton!
	@IBOutlet var twitchButton: CustomisableButton!
	@IBOutlet var lineButton: CustomisableButton!
	
	@IBOutlet var socialOptions3: UIStackView!
	@IBOutlet var githubButton: CustomisableButton!
	
	@IBOutlet var emailTextField: ValidatorTextField!
	@IBOutlet var continueWIthEmailButton: CustomisableButton!
	@IBOutlet var viewMoreOptionsButton: CustomisableButton!
	
	
	private var appleGradient = CAGradientLayer()
	private var googleGradient = CAGradientLayer()
	private var torusObserver: NSObjectProtocol?
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		scrollView.addGestureRecognizer(UITapGestureRecognizer(target: emailTextField, action: #selector(resignFirstResponder)))
		
		socialOptions2.isHidden = true
		socialOptions3.isHidden = true
		
		appleButton.customButtonType = .primary
		appleButton.configuration?.imagePadding = 8
		googleButton.customButtonType = .tertiary
		googleButton.configuration?.imagePadding = 8
		continueWIthEmailButton.customButtonType = .secondary
		
		facebookButton.customButtonType = .secondary
		twitterButton.customButtonType = .secondary
		redditButton.customButtonType = .secondary
		
		discordButton.customButtonType = .secondary
		twitchButton.customButtonType = .secondary
		lineButton.customButtonType = .secondary
		
		githubButton.customButtonType = .secondary
		
		learnMoreButton.configuration?.imagePlacement = .trailing
		learnMoreButton.configuration?.imagePadding = 8
		viewMoreOptionsButton.configuration?.imagePlacement = .trailing
		viewMoreOptionsButton.configuration?.imagePadding = 8
		
		emailTextField.validator = EmailValidator()
		emailTextField.validatorTextFieldDelegate = self
		
		
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
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.scrollView.stopAutoScroll()
		self.torusObserver = nil
	}
	
	
	@IBAction func learnMoreTapped(_ sender: Any) {
		self.alert(withTitle: "Learn More", andMessage: "Info Text")
	}
	
	@IBAction func appleTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.apple] != nil else {
			self.windowError(withTitle: "error".localized(), description: "error-missing-verifier".localized())
			return
		}
		
		self.showLoadingView() // uses differetn callback structure to rest, need to pop loading here
		DependencyManager.shared.torusAuthService.createWallet(from: .apple, displayOver: self.presentedViewController) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.google] != nil else {
			self.windowError(withTitle: "error".localized(), description: "error-missing-verifier".localized())
			return
		}
		
		DependencyManager.shared.torusAuthService.createWallet(from: .google, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func discordTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func twitchTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func lineTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func githubTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func continueWithEmailTapped(_ sender: Any) {
		self.windowError(withTitle: "Not yet supported", description: "This feature is not yet enabled. Please wait for another release")
	}
	
	@IBAction func viewMoreOptionsTapped(_ sender: Any) {
		
		if socialOptions2.isHidden {
			socialOptions2.isHidden = false
			socialOptions3.isHidden = false
			viewMoreOptionsButton.imageView?.rotate(degrees: 180, duration: 0.3)
			
		} else {
			socialOptions2.isHidden = true
			socialOptions3.isHidden = true
			viewMoreOptionsButton.imageView?.rotateBack(duration: 0.3)
		}
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
	
	func handleResult(result: Result<TorusWallet, KukaiError>) {
		switch result {
			case .success(let wallet):
				self.updateLoadingModalStatusLabel(message: "Wallet created, checking for tezos domain registrations")
				
				WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, markSelected: true) { [weak self] success in
					if success {
						self?.navigate()
						
					} else {
						self?.hideLoadingView()
						self?.windowError(withTitle: "error".localized(), description: "error-cant-cache".localized())
					}
				}
				
			case .failure(let error):
				self.hideLoadingView()
				
				// Ignore apple sign in cancelled error
				if error.subType?.domain != "com.apple.AuthenticationServices.AuthorizationError" && error.subType?.code != 1001 {
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

extension CreateWithSocialViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		continueWIthEmailButton.isEnabled = validated
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
