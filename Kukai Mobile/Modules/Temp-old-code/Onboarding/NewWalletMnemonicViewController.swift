//
//  NewWalletMnemonicViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class NewWalletMnemonicViewController: UIViewController {

	@IBOutlet weak var leftStackView: UIStackView!
	@IBOutlet weak var middleStackView: UIStackView!
	@IBOutlet weak var rightStackView: UIStackView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let mnemonic = (WalletCacheService().fetchWallets()?.last as? HDWallet)?.mnemonic {
			
			let words = mnemonic.components(separatedBy: " ")
			var colCount = 0
			var rowCount = 0
			
			for (index, word) in  words.enumerated() {
				
				if colCount == 0 {
					updateLabel(inStackview: leftStackView, atIndex: rowCount, toText: "\(index+1). \(word)")
					colCount += 1
				} else if colCount == 1 {
					updateLabel(inStackview: middleStackView, atIndex: rowCount, toText: "\(index+1). \(word)")
					colCount += 1
				} else {
					updateLabel(inStackview: rightStackView, atIndex: rowCount, toText: "\(index+1). \(word)")
					colCount = 0
					rowCount += 1
				}
			}
			
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to load mnemonic")
		}
	}
	
	func updateLabel(inStackview stackview: UIStackView, atIndex index: Int, toText text: String) {
		if let label = stackview.arrangedSubviews[index] as? UILabel {
			label.text = text
		}
	}
}
