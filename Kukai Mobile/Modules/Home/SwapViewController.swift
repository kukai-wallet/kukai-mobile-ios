//
//  SwapViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/11/2021.
//

import UIKit

class SwapViewController: UIViewController {
	
	@IBOutlet weak var fromTokenButton: UIButton!
	@IBOutlet weak var fromTokentextField: UITextField!
	@IBOutlet weak var toTokenButton: UIButton!
	@IBOutlet weak var toTokenTextField: UITextField!
	@IBOutlet weak var invertTokensButton: UIButton!
	@IBOutlet weak var checkPriceButton: UIButton!
	@IBOutlet weak var swapButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let pair = TransactionService.shared.exchangeData.selectedPair {
			toTokenButton.setTitle(pair.nonBaseTokenSide()?.symbol, for: .normal)
		}
	}
	
	@IBAction func fromTokenTapped(_ sender: Any) {
	}
	
	@IBAction func toTokenTapped(_ sender: Any) {
	}
	
	@IBAction func invertTokensTapped(_ sender: Any) {
	}
	
	@IBAction func checkPriceTapped(_ sender: Any) {
	}
	
	@IBAction func swapButtonTapped(_ sender: Any) {
	}
}
