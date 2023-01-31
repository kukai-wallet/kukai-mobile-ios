//
//  SendTokenConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/01/2023.
//

import Foundation

import UIKit
import KukaiCoreSwift

class SendTokenConfirmViewController: UIViewController {
		
	@IBOutlet weak var largeDisplayStackView: UIStackView!
	@IBOutlet weak var largeDisplayIcon: UIImageView!
	@IBOutlet weak var largeDisplayAmount: UILabel!
	@IBOutlet weak var largeDisplaySymbol: UILabel!
	@IBOutlet weak var largeDisplayFiat: UILabel!
	
	@IBOutlet weak var smallDisplayStackView: UIStackView!
	@IBOutlet weak var smallDisplayIcon: UIImageView!
	@IBOutlet weak var smallDisplayAmount: UILabel!
	@IBOutlet weak var smallDisplayFiat: UILabel!
	
	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var socialIcon: UIImageView!
	@IBOutlet weak var socialAlias: UILabel!
	@IBOutlet weak var socialAddress: UILabel!
	
	@IBOutlet weak var toStackViewRegular: UIStackView!
	@IBOutlet weak var regualrAddress: UILabel!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
}
