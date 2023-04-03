//
//  CreateWithSocialViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class CreateWithSocialViewController: UIViewController {
	
	@IBOutlet var scrollView: UIScrollView!
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
	
	@IBOutlet var emailTextField: UITextField!
	@IBOutlet var continueWIthEmailButton: CustomisableButton!
	@IBOutlet var viewMoreOptionsButton: CustomisableButton!
	
	
	private var appleGradient = CAGradientLayer()
	private var googleGradient = CAGradientLayer()
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		scrollView.addGestureRecognizer(UITapGestureRecognizer(target: emailTextField, action: #selector(resignFirstResponder)))
		
		socialOptions2.isHidden = true
		socialOptions3.isHidden = true
		
		appleButton.configuration?.imagePadding = 8
		googleButton.configuration?.imagePadding = 8
		
		learnMoreButton.configuration?.imagePlacement = .trailing
		learnMoreButton.configuration?.imagePadding = 8
		viewMoreOptionsButton.configuration?.imagePlacement = .trailing
		viewMoreOptionsButton.configuration?.imagePadding = 8
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.startListeningForKeyboard()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.stopListeningForKeyboard()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		appleGradient.removeFromSuperlayer()
		appleGradient = appleButton.addGradientButtonPrimary(withFrame: appleButton.bounds)
		
		googleGradient.removeFromSuperlayer()
		googleGradient = googleButton.addGradientButtonPrimaryBorder()
	}
	
	
	
	@IBAction func appleTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "done", sender: nil)
	}
	
	@IBAction func googleTapped(_ sender: Any) {
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
	}
	
	@IBAction func redditTapped(_ sender: Any) {
	}
	
	@IBAction func discordTapped(_ sender: Any) {
	}
	
	@IBAction func twitchTapped(_ sender: Any) {
	}
	
	@IBAction func lineTapped(_ sender: Any) {
	}
	
	@IBAction func githubTapped(_ sender: Any) {
	}
	
	@IBAction func continueWithEmailTapped(_ sender: Any) {
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
}

extension CreateWithSocialViewController {
	
	func startListeningForKeyboard() {
		NotificationCenter.default.addObserver(self, selector: #selector(customKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(customLeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	func stopListeningForKeyboard() {
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc func customKeyboardWillShow(notification: NSNotification) {
		topSectionContainer.alpha = 0.2
		
		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			let whereKeyboardWillGoToo = ((self.scrollView.frame.height + self.view.safeAreaInsets.bottom) - keyboardSize.height)
			let whereNeedsToBeDisplayed = (continueWIthEmailButton.convert(CGPoint(x: 0, y: 0), to: scrollView).y + continueWIthEmailButton.frame.height + 8).rounded(.up)
			
			if whereKeyboardWillGoToo < whereNeedsToBeDisplayed {
				self.scrollView.contentOffset = CGPoint(x: 0, y: (whereNeedsToBeDisplayed - whereKeyboardWillGoToo))
			}
		}
	}
	
	@objc func customLeyboardWillHide(notification: NSNotification) {
		topSectionContainer.alpha = 1
		
		if let _ = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double), duration != 0 {
			self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
		}
	}
}
