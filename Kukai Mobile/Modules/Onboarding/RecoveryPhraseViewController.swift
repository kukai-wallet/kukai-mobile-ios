//
//  RecoveryPhraseViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit

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
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewSeedWordsButton.customButtonType = .primary
		nextButton.customButtonType = .primary
		
		
		let words = ["word1", "word2", "word3", "word4", "word5", "word6", "word7", "word8", "word9", "word10", "word11", "word12", "word13", "word14", "word15", "word16", "word17", "word18", "word19", "word20", "word21", "word22", "word23", "word24"]
		for (index, word) in  words.enumerated() {
			if let label = value(forKey: "word\(index+1)Label") as? UILabel {
				label.text = word
			}
		}
		
		// Hide the cover view, take screenshot, blur it, display it and cover again
		seedWordCoverContainer.isHidden = true
		let asImage = wordsContainer.asImage()
		let blurryImage = asImage?.addBlur()
		seedWordCoverImageView.image = blurryImage
		seedWordCoverImageView.frame = wordsContainer.bounds
		seedWordCoverImageTintView.frame = wordsContainer.bounds
		seedWordCoverContainer.isHidden = false
    }
	
	@IBAction func viewSeedWordsTapped(_ sender: Any) {
		seedWordCoverContainer.isHidden = true
		nextButton.isEnabled = true
	}
}
