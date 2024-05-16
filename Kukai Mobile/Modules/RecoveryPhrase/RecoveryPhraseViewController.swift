//
//  RecoveryPhraseViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift

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
	private var presentedCopyAlert = false
	private var timer: Timer? = nil
	private var gestureRecognizer: UILongPressGestureRecognizer? = nil
	
	public var sideMenuOption_address: String? = nil
	public var sideMenuOption_isBackedUp: Bool? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		viewSeedWordsButton.customButtonType = .primary
		nextButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		NotificationCenter.default.addObserver(self, selector: #selector(screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
		
		guard let address = (sideMenuOption_address ?? DependencyManager.shared.selectedWalletAddress),
			  let wallet = WalletCacheService().fetchWallet(forAddress: address) else {
			noWallet()
			return
		}
		
		var tempMnemonic: Mnemonic? = nil
		switch wallet.type {
			case .regular, .regularShifted:
				tempMnemonic = (wallet as? RegularWallet)?.mnemonic
				
			case .hd:
				tempMnemonic = (wallet as? HDWallet)?.mnemonic
							
			case .social:
				guard let socialWallet = (wallet as? TorusWallet) else {
					noWallet()
					return
				}
				
				tempMnemonic = Mnemonic.shiftedMnemonic(fromSpskPrivateKey: socialWallet.privateKey)
				
			case .ledger:
				unsupported()
				return
		}
		
		guard let mnemonic = tempMnemonic else {
			noWallet()
			return
		}
		
		
		for (index, word) in mnemonic.words.enumerated() {
			if let label = value(forKey: "word\(index+1)Label") as? UILabel {
				label.text = word
				label.accessibilityIdentifier = "word\(index+1)"
			}
		}
		
		if sideMenuOption_isBackedUp == true {
			nextButton.isHidden = true
		}
		
		
		// Hide the cover view, take screenshot, blur it, display it and cover again
		if !writtenItDown {
			seedWordCoverContainer.isHidden = true
			let asImage = wordsContainer.asImage()
			blurryImage = asImage?.addBlur()
			seedWordCoverContainer.isHidden = false
		}
	}
	
	private func noWallet() {
		self.windowError(withTitle: "error".localized(), description: "error-no-wallet".localized())
		self.navigationController?.popViewController(animated: true)
	}
	
	private func unsupported() {
		self.windowError(withTitle: "error".localized(), description: "error-unsupported-wallet-type".localized())
		self.navigationController?.popViewController(animated: true)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		timer?.invalidate()
		NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		seedWordCoverImageView.image = blurryImage?.resizedImage(size: wordsContainer.frame.size)
		seedWordCoverImageView.frame = wordsContainer.bounds
		seedWordCoverImageTintView.frame = wordsContainer.bounds
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? VerifyRecoveryPhraseViewController {
			vc.sideMenuOption_address = self.sideMenuOption_address
		}
	}
	
	@objc func longPressOnWordContainer() {
		if presentedCopyAlert {
			return
		} else {
			presentedCopyAlert = true
		}
		
		self.alert(withTitle: "Copy?",
				   andMessage: "Do you want to copy the recovery phrase?  This phrase gives anyone access to your wallet and funds, copying it to your system clipboard may expose these words to other apps",
				   okText: "Copy",
				   okStyle: .destructive,
				   okAction: { [weak self] action in
			
			if let address = DependencyManager.shared.selectedWalletAddress, let mnemonic = (WalletCacheService().fetchWallet(forAddress: address) as? HDWallet)?.mnemonic {
				UIPasteboard.general.string = mnemonic.words.joined(separator: " ")
			}
			
			self?.presentedCopyAlert = false
			
		}, cancelText: "Cancel", cancelStyle: .default, cancelAction: { [weak self] action in
			self?.presentedCopyAlert = false
		})
	}
	
	@IBAction func viewSeedWordsTapped(_ sender: Any) {
		seedWordCoverContainer.isHidden = true
		nextButton.isEnabled = true
		
		gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressOnWordContainer))
		wordsContainer.isUserInteractionEnabled = true
		
		if let gr = gestureRecognizer {
			wordsContainer.addGestureRecognizer(gr)
		}
		
		timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false, block: { [weak self] timer in
			self?.timer?.invalidate()
			self?.seedWordCoverContainer.isHidden = false
			self?.nextButton.isEnabled = false
			
			if let gr = self?.gestureRecognizer {
				self?.wordsContainer.removeGestureRecognizer(gr)
			}
		})
	}
	
	private func hideSeedWords() {
		
	}
	
	@IBAction func nextButtonTapped(_ sender: Any) {
		if writtenItDown {
			self.performSegue(withIdentifier: "verify", sender: nil)
			
		} else {
			self.alert(withTitle: "Written the secret Recovery Phrase down?", andMessage: "Without the secret recovery phrase you will not be able to access your key or any assets associated with it.", okText: "Yes", okStyle: .default,
					   okAction: { [weak self] action in
				self?.writtenItDown = true
				self?.performSegue(withIdentifier: "verify", sender: nil)
			}, cancelText: "No", cancelStyle: .default) { action in
				
			}
		}
	}
	
	@objc func screenshotTaken() {
		self.performSegue(withIdentifier: "screenshotWarning", sender: nil)
	}
}
