//
//  VerifyRecoveryPhraseViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit
import KukaiCryptoSwift
import KukaiCoreSwift

class VerifyRecoveryPhraseViewController: UIViewController {
	
	@IBOutlet var selectionTitle1: UILabel!
	@IBOutlet var selection1SeperatorLeft: UIView!
	@IBOutlet var selection1SeperatorRight: UIView!
	@IBOutlet var selection1Button1: UIButton!
	@IBOutlet var selection1Button2: UIButton!
	@IBOutlet var selection1Button3: UIButton!
	
	@IBOutlet var selectionTitle2: UILabel!
	@IBOutlet var selection2SeperatorLeft: UIView!
	@IBOutlet var selection2SeperatorRight: UIView!
	@IBOutlet var selection2Button1: UIButton!
	@IBOutlet var selection2Button2: UIButton!
	@IBOutlet var selection2Button3: UIButton!
	
	@IBOutlet var selectionTitle3: UILabel!
	@IBOutlet var selection3SeperatorLeft: UIView!
	@IBOutlet var selection3SeperatorRight: UIView!
	@IBOutlet var selection3Button1: UIButton!
	@IBOutlet var selection3Button2: UIButton!
	@IBOutlet var selection3Button3: UIButton!
	
	@IBOutlet var selectionTitle4: UILabel!
	@IBOutlet var selection4SeperatorLeft: UIView!
	@IBOutlet var selection4SeperatorRight: UIView!
	@IBOutlet var selection4Button1: UIButton!
	@IBOutlet var selection4Button2: UIButton!
	@IBOutlet var selection4Button3: UIButton!
	
	private var realWordIndexes: [Int] = []
	private var selectedIndexes: [Int] = [-1, -1, -1, -1]
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		setupAccessibility()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Find 4 non-repeating random indexes between 0 and 23
		var randomIndexes: [Int] = []
		while randomIndexes.count < 4 {
			let random = Int.random(in: 0..<24)
			
			if !randomIndexes.contains(where: { $0 == random }) {
				randomIndexes.append(random)
			}
		}
		randomIndexes.sort(by: { $0 < $1 })
		
		selectionTitle1.text = (selectionTitle1.text ?? "") + "\(randomIndexes[0] + 1)"
		selectionTitle2.text = (selectionTitle2.text ?? "") + "\(randomIndexes[1] + 1)"
		selectionTitle3.text = (selectionTitle3.text ?? "") + "\(randomIndexes[2] + 1)"
		selectionTitle4.text = (selectionTitle4.text ?? "") + "\(randomIndexes[3] + 1)"
		
		
		guard let address = DependencyManager.shared.selectedWalletAddress, let mnemonic = (WalletCacheService().fetchWallet(forAddress: address) as? HDWallet)?.mnemonic else {
			self.windowError(withTitle: "error".localized(), description: "Unable to locate wallet information. Please try again")
			self.navigationController?.popViewController(animated: true)
			return
		}
		
		assign(realWord: mnemonic.words[randomIndexes[0]], toButtons: [selection1Button1, selection1Button2, selection1Button3], selectionIndex: 1)
		assign(realWord: mnemonic.words[randomIndexes[1]], toButtons: [selection2Button1, selection2Button2, selection2Button3], selectionIndex: 2)
		assign(realWord: mnemonic.words[randomIndexes[2]], toButtons: [selection3Button1, selection3Button2, selection3Button3], selectionIndex: 3)
		assign(realWord: mnemonic.words[randomIndexes[3]], toButtons: [selection4Button1, selection4Button2, selection4Button3], selectionIndex: 4)
	}
	
	private func assign(realWord: String, toButtons: [UIButton], selectionIndex: Int) {
		let realIndex = Int.random(in: 0..<3)
		realWordIndexes.append(realIndex)
		
		var previousWord: String? = nil
		for index in 0..<3 {
			
			if let button = value(forKey: "selection\(selectionIndex)Button\(index+1)") as? UIButton {
				if index == realIndex {
					button.setTitle(realWord, for: .normal)
				} else {
					let newWord = randomMnemonicWord(excluding: realWord, previousWord: previousWord)
					button.setTitle(newWord, for: .normal)
					previousWord = newWord
				}
			}
		}
	}
	
	private func setupAccessibility() {
		selection1Button1.accessibilityIdentifier = "selection-1-option-1"
		selection1Button2.accessibilityIdentifier = "selection-1-option-2"
		selection1Button3.accessibilityIdentifier = "selection-1-option-3"
		
		selection2Button1.accessibilityIdentifier = "selection-2-option-1"
		selection2Button2.accessibilityIdentifier = "selection-2-option-2"
		selection2Button3.accessibilityIdentifier = "selection-2-option-3"
		
		selection3Button1.accessibilityIdentifier = "selection-3-option-1"
		selection3Button2.accessibilityIdentifier = "selection-3-option-2"
		selection3Button3.accessibilityIdentifier = "selection-3-option-3"
		
		selection4Button1.accessibilityIdentifier = "selection-4-option-1"
		selection4Button2.accessibilityIdentifier = "selection-4-option-2"
		selection4Button3.accessibilityIdentifier = "selection-4-option-3"
	}
	
	private func randomMnemonicWord(excluding: String, previousWord: String?) -> String {
		var word = excluding
		while word == excluding || word == previousWord {
			word = MnemonicWordList_English[Int.random(in: 0..<MnemonicWordList_English.count)]
		}
		
		return word
	}
	
	@IBAction func selection1ButtonTapped(_ sender: UIButton) {
		applySelectedStyle(toButton: sender)
		
		if sender == selection1Button1 {
			selectedIndexes[0] = 0
			applyNormalStyle(toButton: selection1Button2)
			applyNormalStyle(toButton: selection1Button3)
			selection1SeperatorLeft.isHidden = true
			selection1SeperatorRight.isHidden = false
			
		} else if sender == selection1Button2 {
			selectedIndexes[0] = 1
			applyNormalStyle(toButton: selection1Button1)
			applyNormalStyle(toButton: selection1Button3)
			selection1SeperatorLeft.isHidden = true
			selection1SeperatorRight.isHidden = true
			
		} else {
			selectedIndexes[0] = 2
			applyNormalStyle(toButton: selection1Button1)
			applyNormalStyle(toButton: selection1Button2)
			selection1SeperatorLeft.isHidden = false
			selection1SeperatorRight.isHidden = true
		}
		
		compareIndexesAndNavigate()
	}
	
	@IBAction func selection2ButtonTapped(_ sender: UIButton) {
		applySelectedStyle(toButton: sender)
		
		if sender == selection2Button1 {
			selectedIndexes[1] = 0
			applyNormalStyle(toButton: selection2Button2)
			applyNormalStyle(toButton: selection2Button3)
			selection2SeperatorLeft.isHidden = true
			selection2SeperatorRight.isHidden = false
			
		} else if sender == selection2Button2 {
			selectedIndexes[1] = 1
			applyNormalStyle(toButton: selection2Button1)
			applyNormalStyle(toButton: selection2Button3)
			selection2SeperatorLeft.isHidden = true
			selection2SeperatorRight.isHidden = true
			
		} else {
			selectedIndexes[1] = 2
			applyNormalStyle(toButton: selection2Button1)
			applyNormalStyle(toButton: selection2Button2)
			selection2SeperatorLeft.isHidden = false
			selection2SeperatorRight.isHidden = true
		}
		
		compareIndexesAndNavigate()
	}
	
	@IBAction func selection3ButtonTapped(_ sender: UIButton) {
		applySelectedStyle(toButton: sender)
		
		if sender == selection3Button1 {
			selectedIndexes[2] = 0
			applyNormalStyle(toButton: selection3Button2)
			applyNormalStyle(toButton: selection3Button3)
			selection3SeperatorLeft.isHidden = true
			selection3SeperatorRight.isHidden = false
			
		} else if sender == selection3Button2 {
			selectedIndexes[2] = 1
			applyNormalStyle(toButton: selection3Button1)
			applyNormalStyle(toButton: selection3Button3)
			selection3SeperatorLeft.isHidden = true
			selection3SeperatorRight.isHidden = true
			
		} else {
			selectedIndexes[2] = 2
			applyNormalStyle(toButton: selection3Button1)
			applyNormalStyle(toButton: selection3Button2)
			selection3SeperatorLeft.isHidden = false
			selection3SeperatorRight.isHidden = true
		}
		
		compareIndexesAndNavigate()
	}
	
	@IBAction func selection4ButtonTapped(_ sender: UIButton) {
		applySelectedStyle(toButton: sender)
		
		if sender == selection4Button1 {
			selectedIndexes[3] = 0
			applyNormalStyle(toButton: selection4Button2)
			applyNormalStyle(toButton: selection4Button3)
			selection4SeperatorLeft.isHidden = true
			selection4SeperatorRight.isHidden = false
			
		} else if sender == selection4Button2 {
			selectedIndexes[3] = 1
			applyNormalStyle(toButton: selection4Button1)
			applyNormalStyle(toButton: selection4Button3)
			selection4SeperatorLeft.isHidden = true
			selection4SeperatorRight.isHidden = true
			
		} else {
			selectedIndexes[3] = 2
			applyNormalStyle(toButton: selection4Button1)
			applyNormalStyle(toButton: selection4Button2)
			selection4SeperatorLeft.isHidden = false
			selection4SeperatorRight.isHidden = true
		}
		
		compareIndexesAndNavigate()
	}
	
	private func applySelectedStyle(toButton button: UIButton) {
		button.backgroundColor = .colorNamed("BG6")
		button.isSelected = true
		button.addShadow(color: .black.withAlphaComponent(0.04), opacity: 1, offset: CGSize(width: 0, height: 3), radius: 1)
		button.addShadow(color: .black.withAlphaComponent(0.12), opacity: 1, offset: CGSize(width: 0, height: 3), radius: 8)
	}
	
	private func applyNormalStyle(toButton button: UIButton) {
		button.backgroundColor = .clear
		button.isSelected = false
		
		for layer in button.layer.sublayers ?? [] {
			if layer.shadowPath != nil {
				layer.removeFromSuperlayer()
			}
		}
	}
	
	private func compareIndexesAndNavigate() {
		if realWordIndexes.contains(selectedIndexes) {
			guard let address = DependencyManager.shared.selectedWalletAddress else {
				return
			}
			
			var metadata = DependencyManager.shared.walletList.metadata(forAddress: address)
			metadata?.backedUp = true
			
			guard let meta = metadata else {
				return
			}
			
			let walletCache = WalletCacheService()
			let _ = DependencyManager.shared.walletList.update(address: address, with: meta)
			let _ = walletCache.writeNonsensitive(DependencyManager.shared.walletList)
			
			DependencyManager.shared.walletList = walletCache.readNonsensitive()
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: address)
			
			self.navigate()
		}
	}
	
	private func navigate() {
		let sideMenuBackViewController = self.navigationController?.viewControllers.filter({ $0 is SideMenuBackupViewController }).first
		let accountsViewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		
		if let backup = sideMenuBackViewController {
			self.navigationController?.popToViewController(backup, animated: true)
			
		} else if let accounts = accountsViewController {
			self.navigationController?.popToViewController(accounts, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.navigationController?.popToHome()
		}
	}
}
