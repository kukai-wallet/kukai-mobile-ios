//
//  RecoveryPhraseViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit
import KukaiCoreSwift

class RecoveryPhraseViewController: UIViewController {
	
	@IBOutlet var wordsContainer: UIView!
	@IBOutlet var word1Label: UILabel!
	@IBOutlet var word2Label: UILabel!
	@IBOutlet var word3Label: UILabel!
	@IBOutlet var word4Label: UILabel!
	@IBOutlet var word5Label: UILabel!
	@IBOutlet var word6Label: UILabel!
	@IBOutlet var word7Label: UILabel!
	@IBOutlet var word8Label: UILabel!
	@IBOutlet var word9Label: UILabel!
	@IBOutlet var word10Label: UILabel!
	@IBOutlet var word11Label: UILabel!
	@IBOutlet var word12Label: UILabel!
	@IBOutlet var word13Label: UILabel!
	@IBOutlet var word14Label: UILabel!
	@IBOutlet var word15Label: UILabel!
	@IBOutlet var word16Label: UILabel!
	@IBOutlet var word17Label: UILabel!
	@IBOutlet var word18Label: UILabel!
	@IBOutlet var word19Label: UILabel!
	@IBOutlet var word20Label: UILabel!
	@IBOutlet var word21Label: UILabel!
	@IBOutlet var word22Label: UILabel!
	@IBOutlet var word23Label: UILabel!
	@IBOutlet var word24Label: UILabel!
	@IBOutlet var seedWordCoverContainer: UIView!
	@IBOutlet var seedWordCoverImageView: UIImageView!
	@IBOutlet var seedWordCoverImageTintView: UIView!
	@IBOutlet var viewSeedWordsButton: CustomisableButton!
	@IBOutlet var nextButton: CustomisableButton!
	
	private var blurryImage: UIImage? = nil
	private var writtenItDown = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewSeedWordsButton.customButtonType = .primary
		nextButton.customButtonType = .primary
		
		guard let address = DependencyManager.shared.selectedWalletAddress, let mnemonic = (WalletCacheService().fetchWallet(forAddress: address) as? HDWallet)?.mnemonic else {
			self.navigationController?.previousViewController()?.alert(errorWithMessage: "Unable to locate wallet information. Please try again")
			self.navigationController?.popViewController(animated: true)
			return
		}
		
		for (index, word) in mnemonic.words.enumerated() {
			if let label = value(forKey: "word\(index+1)Label") as? UILabel {
				label.text = word
			}
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		NotificationCenter.default.addObserver(self, selector: #selector(screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
		
		// Hide the cover view, take screenshot, blur it, display it and cover again
		if !writtenItDown {
			seedWordCoverContainer.isHidden = true
			let asImage = wordsContainer.asImage()
			blurryImage = asImage?.addBlur()
			seedWordCoverContainer.isHidden = false
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		seedWordCoverImageView.image = blurryImage?.resizedImage(size: wordsContainer.frame.size)
		seedWordCoverImageView.frame = wordsContainer.bounds
		seedWordCoverImageTintView.frame = wordsContainer.bounds
	}
	
	@IBAction func viewSeedWordsTapped(_ sender: Any) {
		seedWordCoverContainer.isHidden = true
		nextButton.isEnabled = true
	}
	
	@IBAction func nextButtonTapped(_ sender: Any) {
		if writtenItDown {
			self.performSegue(withIdentifier: "verify", sender: nil)
			
		} else {
			let alert = UIAlertController(title: "Written the secret Recovery Phrase down?", message: "Without the secret recovery phrase you will not be able to access your key or any assets associated with it.", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] action in
				self?.writtenItDown = true
				self?.performSegue(withIdentifier: "verify", sender: nil)
			}))
			
			self.present(alert, animated: true)
		}
	}
	
	@objc func screenshotTaken() {
		self.performSegue(withIdentifier: "screenshotWarning", sender: nil)
	}
}
