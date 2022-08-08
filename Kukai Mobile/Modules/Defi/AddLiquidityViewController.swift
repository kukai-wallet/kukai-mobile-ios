//
//  AddLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2022.
//

import UIKit
import KukaiCoreSwift

class AddLiquidityViewController: UIViewController {

	@IBOutlet weak var token1Icon: UIImageView!
	@IBOutlet weak var token1Button: UIButton!
	@IBOutlet weak var token1Textfield: ValidatorTextField!
	@IBOutlet weak var token1BalanceLabel: UILabel!
	@IBOutlet weak var token1MaxButton: UIButton!
	
	@IBOutlet weak var token2icon: UIImageView!
	@IBOutlet weak var token2Button: UIButton!
	@IBOutlet weak var token2Textfield: ValidatorTextField!
	@IBOutlet weak var token2BalanceLabel: UILabel!
	@IBOutlet weak var token2MaxButton: UIButton!
	
	@IBOutlet weak var addButton: UIButton!
	
	
	private var xtzBalance: XTZAmount = .zero()
	private var tokenData: (token: Token, isNFT: Bool)? = nil
	private var tokenBalance: TokenAmount = TokenAmount.zero()
	private var calculationResult: DexAddCalculationResult? = nil
	private var previousExchange: DipDupExchange? = nil
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		addButton.isHidden = true
		token1MaxButton.isHidden = true
		token2MaxButton.isHidden = true
		
		token1Textfield.validatorTextFieldDelegate = self
		token2Textfield.validatorTextFieldDelegate = self
		
		token1BalanceLabel.text = ""
		token2BalanceLabel.text = ""
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		token1Textfield.text = ""
		token2Textfield.text = ""
		updateTokenDisplayDetails()
	}
	
	
	
	// MARK: - Helpers
	
	func updateTokenDisplayDetails() {
		guard let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken else {
			return
		}
		
		if previousExchange != exchange {
			resetInputs()
		}
		
		previousExchange = exchange
		token1MaxButton.isHidden = false
		token2MaxButton.isHidden = false
		
		xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address)
		tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
		
		token1Textfield.validator = TokenAmountValidator(balanceLimit: xtzBalance)
		token1BalanceLabel.text = "Balance: \(xtzBalance.normalisedRepresentation)"
		
		MediaProxyService.load(url: tokenIconURL, to: token2icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: token2icon.frame.size)
		token2Button.setTitle(exchange.token.symbol, for: .normal)
		token2BalanceLabel.text = "Balance: \(tokenBalance.normalisedRepresentation)"
	}
	
	func resetInputs() {
		token1Textfield.text = ""
		let _ = token1Textfield.revalidateTextfield()
	}
	
	func updateRates(withXtzInput: String?, withTokenInput: String?) {
		guard let exchange = TransactionService.shared.addLiquidityData.selectedExchangeAndToken else {
			self.alert(withTitle: "Error", andMessage: "Can't get pair data")
			return
		}
		
		if withXtzInput == "" || withTokenInput == "" {
			token1Textfield.text = ""
			token2Textfield.text = ""
			return
		}
		
		
		if let xtzInput = withXtzInput, let xtz = XTZAmount(fromNormalisedAmount: xtzInput, decimalPlaces: 6) {
			self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(xtz: xtz, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), totalLiquidity: exchange.totalLiquidity(), maxSlippage: 0.005, dex: exchange.name)
			token2Textfield.text = self.calculationResult?.tokenRequired.normalisedRepresentation ?? ""
			
			TransactionService.shared.addLiquidityData.token1 = xtz
			TransactionService.shared.addLiquidityData.token2 = self.calculationResult?.tokenRequired
			
		} else if let tokenInput = withTokenInput, let token = TokenAmount(fromNormalisedAmount: tokenInput, decimalPlaces: exchange.token.decimals) {
			self.calculationResult = DexCalculationService.shared.calculateAddLiquidity(token: token, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), totalLiquidity: exchange.totalLiquidity(), maxSlippage: 0.005, dex: exchange.name)
			token1Textfield.text = self.calculationResult?.tokenRequired.normalisedRepresentation ?? ""
			
			TransactionService.shared.addLiquidityData.token1 = self.calculationResult?.tokenRequired
			TransactionService.shared.addLiquidityData.token2 = token
		}
		
		TransactionService.shared.addLiquidityData.calculationResult = self.calculationResult
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func token2ButtonTapped(_ sender: Any) {
	}
	
	@IBAction func token1MaxTapped(_ sender: Any) {
		token1Textfield.text = self.xtzBalance.normalisedRepresentation
		let _ = token1Textfield.revalidateTextfield()
	}
	
	@IBAction func token2MaxTapped(_ sender: Any) {
		token2Textfield.text = self.tokenBalance.normalisedRepresentation
		let _ = token2Textfield.revalidateTextfield()
	}
	
	@IBAction func addTapped(_ sender: Any) {
	}
}

extension AddLiquidityViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated && textfield == token1Textfield {
			updateRates(withXtzInput: text, withTokenInput: nil)
			
		} else if validated {
			updateRates(withXtzInput: nil, withTokenInput: text)
		}
	}
}
