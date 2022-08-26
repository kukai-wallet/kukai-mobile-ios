//
//  SwapViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//

import UIKit
import KukaiCoreSwift

class SwapViewController: UIViewController {
	
	@IBOutlet weak var tokenFromIcon: UIImageView!
	@IBOutlet weak var tokenFromButton: UIButton!
	@IBOutlet weak var tokenFromTextField: ValidatorTextField!
	@IBOutlet weak var tokenFromBalance: UILabel!
	@IBOutlet weak var invertTokensButton: UIButton!
	
	@IBOutlet weak var tokenToIcon: UIImageView!
	@IBOutlet weak var tokenToButton: UIButton!
	@IBOutlet weak var tokenToTextField: UITextField!
	@IBOutlet weak var tokenToBalance: UILabel!
	@IBOutlet weak var exchangeRateLabel: UILabel!
	
	@IBOutlet weak var viewDetailsButton: UIButton!
	@IBOutlet weak var viewDetailsVerticalPaddingView: UIView!
	@IBOutlet weak var viewDetailsStackView1: UIStackView!
	@IBOutlet weak var viewDetailsStackView2: UIStackView!
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	@IBOutlet weak var gasCostButton: UIButton!
	@IBOutlet weak var previewButton: UIButton!
	
	private var isDetailsOpen = true
	private var xtzToToken = true
	private var calculationResult: DexSwapCalculationResult? = nil
	private var previousExchange: DipDupExchange? = nil
	
	
	
	// MARK: - Setup
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		TransactionService.shared.currentTransactionType = .exchange
		
		showDetails(false, animated: false)
		
		tokenFromButton.setTitle("XTZ", for: .normal)
		tokenFromTextField.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		tokenFromTextField.isEnabled = false
		tokenFromTextField.validatorTextFieldDelegate = self
		
		tokenFromBalance.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation)"
		tokenToBalance.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation)"
		invertTokensButton.isEnabled = false
		
		tokenToButton.setTitle("...", for: .normal)
		tokenToTextField.isEnabled = false
		exchangeRateLabel.text = ""
		
		viewDetailsButton.isHidden = true
		feeLabel.text = "0 tez"
		storageCostLabel.text = "0 tez"
		
		previewButton.isHidden = true
		
		
		// Default to first token available
		if TransactionService.shared.exchangeData.selectedExchangeAndToken == nil {
			TransactionService.shared.exchangeData.selectedExchangeAndToken = DependencyManager.shared.balanceService.exchangeData[0].exchanges.last
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tokenFromTextField.text = ""
		tokenToTextField.text = ""
		updateTokenDisplayDetails()
	}
	
	
	
	// MARK: - Helpers
	
	func showDetails(_ show: Bool, animated: Bool) {
		isDetailsOpen = show
		
		viewDetailsVerticalPaddingView.isHidden = !show
		viewDetailsStackView1.isHidden = !show
		viewDetailsStackView2.isHidden = !show
		
		if show {
			viewDetailsButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
		} else {
			viewDetailsButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
		}
		
		if animated {
			UIView.animate(withDuration: 0.3) {
				self.view.layoutIfNeeded()
			}
		}
	}
	
	func updateTokenDisplayDetails() {
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			return
		}
		
		if previousExchange != exchange {
			resetInputs()
			disableDetailsAndPreview()
		}
		
		previousExchange = exchange
		invertTokensButton.isEnabled = true
		tokenFromTextField.isEnabled = true
		
		let xtzBalance = DependencyManager.shared.balanceService.account.xtzBalance
		let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
		let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address)
		let tokenBalance = tokenData?.token.balance ?? TokenAmount.zero()
		
		if xtzToToken {
			tokenFromIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenFromButton.setTitle("XTZ", for: .normal)
			tokenFromTextField.validator = TokenAmountValidator(balanceLimit: xtzBalance)
			tokenFromBalance.text = "Balance: \(xtzBalance.normalisedRepresentation)"
			
			MediaProxyService.load(url: tokenIconURL, to: tokenToIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenToIcon.frame.size)
			tokenToButton.setTitle(exchange.token.symbol, for: .normal)
			tokenToBalance.text = "Balance: \(tokenBalance.normalisedRepresentation)"
			
			let marketRate = DexCalculationService.shared.xtzToTokenMarketRate(xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount())
			exchangeRateLabel.text = "1 XTZ = \(marketRate ?? 0) \(exchange.token.symbol)"
			
		} else {
			MediaProxyService.load(url: tokenIconURL, to: tokenFromIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenFromIcon.frame.size)
			tokenFromButton.setTitle(exchange.token.symbol, for: .normal)
			
			tokenFromTextField.validator = TokenAmountValidator(balanceLimit: tokenData?.token.balance ?? TokenAmount.zero(), decimalPlaces: exchange.token.decimals)
			tokenFromBalance.text = "Balance: \(tokenBalance.normalisedRepresentation)"
			
			tokenToIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenToButton.setTitle("XTZ", for: .normal)
			tokenToBalance.text = "Balance: \(xtzBalance.normalisedRepresentation)"
			
			let marketRate = DexCalculationService.shared.tokenToXtzMarketRate(xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount())
			exchangeRateLabel.text = "1 \(exchange.token.symbol) = \(marketRate ?? 0) tez"
		}
	}
	
	func updateRates(withInput: String) {
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			self.alert(withTitle: "Error", andMessage: "Can't get pair data")
			return
		}
		
		if withInput == "" {
			tokenToTextField.text = "0"
			exchangeRateLabel.text = ""
			return
		}
		
		if xtzToToken {
			guard let xtz = XTZAmount(fromNormalisedAmount: withInput, decimalPlaces: 6) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			TransactionService.shared.exchangeData.fromAmount = xtz
			
			self.calculationResult = DexCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: exchange.name)
			exchangeRateLabel.text = "1 XTZ = \(self.calculationResult?.displayExchangeRate ?? 0) \(exchange.token.symbol)"
			
		} else {
			guard let token = TokenAmount(fromNormalisedAmount: withInput, decimalPlaces: 8) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			TransactionService.shared.exchangeData.fromAmount = token
			
			self.calculationResult = DexCalculationService.shared.calculateTokenToXTZ(tokenToSell: token, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.005, dex: exchange.name)
			exchangeRateLabel.text = "1 \(exchange.token.symbol) = \(self.calculationResult?.displayExchangeRate ?? 0) XTZ"
		}
		
		guard let calc = self.calculationResult else {
			tokenToTextField.text = "0"
			return
		}
		
		tokenToTextField.text = calc.expected.normalisedRepresentation
		
		TransactionService.shared.exchangeData.calculationResult = self.calculationResult
		TransactionService.shared.exchangeData.isXtzToToken = xtzToToken
		TransactionService.shared.exchangeData.toAmount = self.calculationResult?.expected
		TransactionService.shared.exchangeData.exchangeRateString = exchangeRateLabel.text
	}
	
	@objc func estimate() {
		guard let calc = calculationResult, calc.minimum > TokenAmount.zero(), let wallet = DependencyManager.shared.selectedWallet, let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			self.alert(withTitle: "Error", andMessage: "Invalid calculation or wallet")
			return
		}
		
		self.showLoadingModal(completion: nil)
		var operations: [KukaiCoreSwift.Operation] = []
		
		if xtzToToken, let input = tokenFromTextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) {
			operations = OperationFactory.swapXtzToToken(withDex: exchange, xtzAmount: xtz, minTokenAmount: calc.minimum, wallet: wallet, timeout: 60 * 5)
			
		} else if let input = tokenFromTextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: exchange.token.decimals) {
			operations = OperationFactory.swapTokenToXTZ(withDex: exchange, tokenAmount: token, minXTZAmount: calc.minimum as? XTZAmount ?? XTZAmount.zero(), wallet: wallet, timeout: 60 * 5)
		}
		
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] result in
			self?.hideLoadingModal(completion: nil)
			
			switch result {
				case .success(let ops):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: ops)
					self?.enableDetailsAndPreview()
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
	
	func enableDetailsAndPreview() {
		let totalFee = TransactionService.shared.currentOperationsAndFeesData.fee
		let totalStorage = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost
		
		feeLabel.text = totalFee.normalisedRepresentation + " xtz"
		storageCostLabel.text = totalStorage.normalisedRepresentation + " xtz"
		
		viewDetailsButton.isHidden = false
		previewButton.isHidden = false
		
		tokenFromTextField.resignFirstResponder()
		tokenToTextField.resignFirstResponder()
	}
	
	func disableDetailsAndPreview() {
		TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: [])
		
		viewDetailsButton.isHidden = true
		previewButton.isHidden = true
	}
	
	func resetInputs() {
		tokenFromTextField.text = ""
		let _ = tokenFromTextField.revalidateTextfield()
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func tokenFromTapped(_ sender: Any) {
		xtzToToken = false
	}
	
	@IBAction func maxTapped(_ sender: Any) {
		let balLimit = (tokenFromTextField.validator as? TokenAmountValidator)?.balanceLimit
		tokenFromTextField.text = balLimit?.normalisedRepresentation
		
		let _ = tokenFromTextField.revalidateTextfield()
		estimate()
	}
	
	@IBAction func tokenToTapped(_ sender: Any) {
		xtzToToken = true
	}
	
	@IBAction func invertTokensTapped(_ sender: Any) {
		xtzToToken = !xtzToToken
		
		tokenFromTextField.text = ""
		tokenToTextField.text = ""
		
		updateTokenDisplayDetails()
		disableDetailsAndPreview()
	}
	
	@IBAction func viewDetailsTapped(_ sender: Any) {
		showDetails(!isDetailsOpen, animated: true)
	}
	
	@IBAction func refreshRates(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		
		let walletAddress = DependencyManager.shared.selectedWallet?.address ?? ""
		DependencyManager.shared.balanceService.fetchAllBalancesTokensAndPrices(forAddress: walletAddress, refreshType: .refreshEverything) { [weak self] error in
			
			self?.hideLoadingModal()
			if let err = error {
				self?.alert(errorWithMessage: err.description)
				return
			}
			
			if let selectedExchange = TransactionService.shared.exchangeData.selectedExchangeAndToken {
				
				// Grab the updated exchange data
				DependencyManager.shared.balanceService.exchangeData.forEach { obj in
					obj.exchanges.forEach { exchange in
						if exchange.address == selectedExchange.address {
							TransactionService.shared.exchangeData.selectedExchangeAndToken = exchange
							return
						}
					}
				}
				
				// Update the UI
				self?.updateRates(withInput: self?.tokenFromTextField.text ?? "")
			}
		}
	}
}

extension SwapViewController: ValidatorTextFieldDelegate {
	
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
