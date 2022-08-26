//
//  RemoveLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2022.
//

import UIKit
import KukaiCoreSwift

class RemoveLiquidityViewController: UIViewController {

	@IBOutlet weak var lpToken1Icon: UIImageView!
	@IBOutlet weak var lpToken2Icon: UIImageView!
	@IBOutlet weak var lpTokenButton: UIButton!
	@IBOutlet weak var lpTokenTextfield: ValidatorTextField!
	@IBOutlet weak var lpTokenBalance: UILabel!
	@IBOutlet weak var lpTokenMaxButton: UIButton!
	
	@IBOutlet weak var outputToken1Icon: UIImageView!
	@IBOutlet weak var outputToken1Button: UIButton!
	@IBOutlet weak var outputToken1Textfield: ValidatorTextField!
	@IBOutlet weak var outputToken1Balance: UILabel!
	
	@IBOutlet weak var outputToken2Icon: UIImageView!
	@IBOutlet weak var outputToken2Button: UIButton!
	@IBOutlet weak var outputToken2Textfield: ValidatorTextField!
	@IBOutlet weak var outputToken2Balance: UILabel!
	
	@IBOutlet weak var removeButton: UIButton!
	
	
	private var xtzBalance: XTZAmount = .zero()
	private var lqtTokenBalance: TokenAmount = TokenAmount.zero()
	private var tokenData: (token: Token, isNFT: Bool)? = nil
	private var tokenBalance: TokenAmount = TokenAmount.zero()
	private var calculationResult: DexRemoveCalculationResult? = nil
	private var previousPosition: DipDupPositionData? = nil
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		lpTokenTextfield.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		lpTokenTextfield.validatorTextFieldDelegate = self
		
		removeButton.isHidden = true
		lpTokenMaxButton.isHidden = true
		lpTokenBalance.text = ""
		
		outputToken1Textfield.isEnabled = false
		outputToken1Balance.text = ""
		outputToken2Textfield.isEnabled = false
		outputToken2Balance.text = ""
		
		// Default to first token available
		if TransactionService.shared.removeLiquidityData.position == nil {
			TransactionService.shared.removeLiquidityData.position = DependencyManager.shared.balanceService.account.liquidityTokens.first
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		outputToken1Textfield.text = ""
		outputToken1Textfield.text = ""
		updateTokenDisplayDetails()
	}
	
	
	
	// MARK: - Helpers
	
	func updateTokenDisplayDetails() {
		guard let position = TransactionService.shared.removeLiquidityData.position else {
			return
		}
		
		if previousPosition != position {
			resetInputs()
		}
		
		previousPosition = position
		lpTokenMaxButton.isHidden = false
		
		
		lqtTokenBalance = position.tokenAmount()
		xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		tokenData = DependencyManager.shared.balanceService.token(forAddress: position.exchange.token.address)
		tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: position.exchange.token.address)
		
		MediaProxyService.load(url: tokenIconURL, to: lpToken2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: lpToken2Icon.frame.size)
		lpTokenButton.setTitle("XTZ/\(position.exchange.token.symbol)", for: .normal)
		lpTokenTextfield.validator = TokenAmountValidator(balanceLimit: lqtTokenBalance, decimalPlaces: lqtTokenBalance.decimalPlaces)
		lpTokenBalance.text = "Balance: \(lqtTokenBalance.normalisedRepresentation)"
		
		outputToken1Balance.text = "Balance: \(xtzBalance.normalisedRepresentation)"
		
		MediaProxyService.load(url: tokenIconURL, to: outputToken2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: outputToken2Icon.frame.size)
		outputToken2Button.setTitle(position.exchange.token.symbol, for: .normal)
		outputToken2Balance.text = "Balance: \(tokenBalance.normalisedRepresentation)"
	}
	
	func resetInputs() {
		lpTokenTextfield.text = ""
		let _ = lpTokenTextfield.revalidateTextfield()
	}
	
	func updateRates(withInput: String) {
		guard let position = TransactionService.shared.removeLiquidityData.position else {
			self.alert(withTitle: "Error", andMessage: "Can't get pair data")
			return
		}
		
		if withInput == "" {
			lpTokenTextfield.text = ""
			outputToken1Textfield.text = ""
			outputToken2Textfield.text = ""
			return
		}
		
		let lqtTokenAmount = TokenAmount(fromNormalisedAmount: withInput, decimalPlaces: position.exchange.liquidityTokenDecimalPlaces()) ?? TokenAmount.zero()
		self.calculationResult = DexCalculationService.shared.calculateRemoveLiquidity(liquidityBurned: lqtTokenAmount, totalLiquidity: position.exchange.totalLiquidity(), xtzPool: position.exchange.xtzPoolAmount(), tokenPool: position.exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: position.exchange.name)
		
		outputToken1Textfield.text = self.calculationResult?.expectedXTZ.normalisedRepresentation ?? ""
		outputToken2Textfield.text = self.calculationResult?.expectedToken.normalisedRepresentation ?? ""
		
		TransactionService.shared.removeLiquidityData.tokenAmount = lqtTokenAmount
		TransactionService.shared.removeLiquidityData.calculationResult = self.calculationResult
	}
	
	@objc func estimate() {
		guard let calc = calculationResult, calc.expectedToken > TokenAmount.zero(),
			  let wallet = DependencyManager.shared.selectedWallet,
			  let position = TransactionService.shared.removeLiquidityData.position,
			  let lpTokenInput = lpTokenTextfield.text, let lpTokenAmount = TokenAmount(fromNormalisedAmount: lpTokenInput, decimalPlaces: position.exchange.liquidityTokenDecimalPlaces())
		else {
			self.alert(withTitle: "Error", andMessage: "Invalid calculation or wallet")
			return
		}
		
		lpTokenTextfield.resignFirstResponder()
		
		self.showLoadingModal(completion: nil)
		let operations = OperationFactory.removeLiquidity(withDex: position.exchange, minXTZ: calc.minimumXTZ, minToken: calc.minimumToken, liquidityToBurn: lpTokenAmount, wallet: wallet, timeout: 60 * 5)
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			self?.hideLoadingModal(completion: nil)
			
			switch result {
				case .success(let ops):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: ops)
					self?.removeButton.isHidden = false
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func lpTokenTapped(_ sender: Any) {
	}
	
	@IBAction func lpTokenMaxTapped(_ sender: Any) {
		lpTokenTextfield.text = lqtTokenBalance.normalisedRepresentation
		let _ = lpTokenTextfield.revalidateTextfield()
	}
}

extension RemoveLiquidityViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			updateRates(withInput: text)
		}
	}
}
