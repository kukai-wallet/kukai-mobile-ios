//
//  RemoveLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2022.
//

import UIKit

class RemoveLiquidityViewController: UIViewController {

	@IBOutlet weak var lpToken1Icon: UIImageView!
	@IBOutlet weak var lpToken2Icon: UIImageView!
	@IBOutlet weak var lpTokenButton: UIButton!
	@IBOutlet weak var lpTokenTextfield: ValidatorTextField!
	@IBOutlet weak var lpTokenBalance: UILabel!
	
	@IBOutlet weak var outputToken1Icon: UIImageView!
	@IBOutlet weak var outputToken1Button: UIButton!
	@IBOutlet weak var outputToken1Textfield: ValidatorTextField!
	@IBOutlet weak var outputToken1Balance: UILabel!
	
	@IBOutlet weak var outputToken2Icon: UIImageView!
	@IBOutlet weak var outputToken2Button: UIButton!
	@IBOutlet weak var outputToken2Textfield: ValidatorTextField!
	@IBOutlet weak var outputToken2Balance: UILabel!
	
	@IBOutlet weak var removeButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	
	
	// MARK: - Actions
	
	@IBAction func lpTokenTapped(_ sender: Any) {
	}
	
	@IBAction func lpTokenMaxTapped(_ sender: Any) {
	}
	
	@IBAction func removeTapped(_ sender: Any) {
	}
}
