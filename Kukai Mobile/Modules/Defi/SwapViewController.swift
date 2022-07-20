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
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var invertTokensButton: UIButton!
	
	@IBOutlet weak var tokenToIcon: UIImageView!
	@IBOutlet weak var tokenToButton: UIButton!
	@IBOutlet weak var tokenToTextField: UITextField!
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
	
	
	
	// MARK: - Setup
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		TransactionService.shared.currentTransactionType = .exchange
		
		showDetails(false, animated: false)
		
		tokenFromButton.setTitle("XTZ", for: .normal)
		tokenFromTextField.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		tokenFromTextField.isEnabled = false
		
		balanceLabel.text = "Balance: \(DependencyManager.shared.balanceService.account.xtzBalance.normalisedRepresentation) tez"
		invertTokensButton.isEnabled = false
		
		tokenToButton.setTitle("...", for: .normal)
		tokenToTextField.isEnabled = false
		exchangeRateLabel.text = "1 XTZ = ..."
		
		viewDetailsButton.isHidden = true
		feeLabel.text = "0 tez"
		storageCostLabel.text = "0 tez"
		
		previewButton.isHidden = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
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
		
		invertTokensButton.isEnabled = true
		tokenFromTextField.isEnabled = true
		
		if xtzToToken {
			tokenFromIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenFromButton.setTitle("XTZ", for: .normal)
			
			let balance = DependencyManager.shared.balanceService.account.xtzBalance
			tokenFromTextField.validator = TokenAmountValidator(balanceLimit: balance)
			balanceLabel.text = "Balance: \(balance.normalisedRepresentation) tez"
			
			
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenToIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenToIcon.frame.size)
			tokenToButton.setTitle(exchange.token.symbol, for: .normal)
			
		} else {
			
			let tokenIconURL = DependencyManager.shared.tzktClient.avatarURL(forToken: exchange.token.address)
			MediaProxyService.load(url: tokenIconURL, to: tokenFromIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenFromIcon.frame.size)
			tokenFromButton.setTitle(exchange.token.symbol, for: .normal)
			
			let tokenData = DependencyManager.shared.balanceService.token(forAddress: exchange.token.address)
			let balance = tokenData?.token.balance ?? TokenAmount.zero()
			tokenFromTextField.validator = TokenAmountValidator(balanceLimit: tokenData?.token.balance ?? TokenAmount.zero(), decimalPlaces: exchange.token.decimals)
			balanceLabel.text = "Balance: \(balance.normalisedRepresentation) \(exchange.token.symbol)"
			
			
			tokenToIcon.image = UIImage(named: "tezos-xtz-logo")
			tokenToButton.setTitle("XTZ", for: .normal)
		}
	}
	
	func updateRates() {
		guard let exchange = TransactionService.shared.exchangeData.selectedExchangeAndToken else {
			self.alert(withTitle: "Error", andMessage: "Can't get pair data")
			return
		}
		
		if xtzToToken {
			guard let input = tokenFromTextField.text, let xtz = XTZAmount(fromNormalisedAmount: input, decimalPlaces: 6) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexCalculationService.shared.calculateXtzToToken(xtzToSell: xtz, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.5, dex: exchange.name)
			
		} else {
			guard let input = tokenFromTextField.text, let token = TokenAmount(fromNormalisedAmount: input, decimalPlaces: 8) else {
				self.alert(withTitle: "Error", andMessage: "Invalid amount of XTZ")
				return
			}
			
			self.calculationResult = DexCalculationService.shared.calculateTokenToXTZ(tokenToSell: token, xtzPool: exchange.xtzPoolAmount(), tokenPool: exchange.tokenPoolAmount(), maxSlippage: 0.5, dex: exchange.name)
		}
		
		
		guard let calc = self.calculationResult else {
			tokenToTextField.text = "0"
			return
		}
		
		tokenToTextField.text = calc.expected.normalisedRepresentation
	}
	
	@objc func estimate() {
		
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func settingsTapped(_ sender: Any) {
	}
	
	@IBAction func tokenFromTapped(_ sender: Any) {
		xtzToToken = false
	}
	
	@IBAction func maxTapped(_ sender: Any) {
	}
	
	@IBAction func tokenToTapped(_ sender: Any) {
		xtzToToken = true
	}
	
	@IBAction func invertTokensTapped(_ sender: Any) {
		xtzToToken = !xtzToToken
		updateTokenDisplayDetails()
	}
	
	@IBAction func viewDetailsTapped(_ sender: Any) {
		showDetails(!isDetailsOpen, animated: true)
	}
	
	@IBAction func infoTapped(_ sender: Any) {
	}
	
	@IBAction func gasCostTapped(_ sender: Any) {
	}
	
	@IBAction func previewTapped(_ sender: Any) {
	}
}
