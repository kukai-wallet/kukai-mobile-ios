//
//  CreateWithSocialViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

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
		
		appleButton.customButtonType = .primary
		appleButton.configuration?.imagePadding = 8
		googleButton.customButtonType = .tertiary
		googleButton.configuration?.imagePadding = 8
		continueWIthEmailButton.customButtonType = .secondary
		
		learnMoreButton.configuration?.imagePlacement = .trailing
		learnMoreButton.configuration?.imagePadding = 8
		viewMoreOptionsButton.configuration?.imagePlacement = .trailing
		viewMoreOptionsButton.configuration?.imagePadding = 8
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.scrollView.setupAutoScroll(focusView: continueWIthEmailButton, parentView: self.view)
		self.scrollView.autoScrollDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.scrollView.stopAutoScroll()
	}
	
	
	
	@IBAction func appleTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "done", sender: nil)
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		self.continueWIthEmailButton.isEnabled = !self.continueWIthEmailButton.isEnabled 
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
