//
//  CreateWithSocialViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class CreateWithSocialViewController: UIViewController {
	
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
		
		socialOptions2.isHidden = true
		socialOptions3.isHidden = true
		
		appleButton.configuration?.imagePadding = 8
		googleButton.configuration?.imagePadding = 8
		
		learnMoreButton.configuration?.imagePlacement = .trailing
		learnMoreButton.configuration?.imagePadding = 8
		viewMoreOptionsButton.configuration?.imagePlacement = .trailing
		viewMoreOptionsButton.configuration?.imagePadding = 8
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		appleGradient.removeFromSuperlayer()
		appleGradient = appleButton.addGradientButtonPrimary(withFrame: appleButton.bounds)
		
		googleGradient.removeFromSuperlayer()
		googleGradient = googleButton.addGradientButtonPrimaryBorder()
	}
	
	
	
	@IBAction func appleTapped(_ sender: Any) {
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
