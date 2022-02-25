//
//  SendEnterAmountViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import KukaiCoreSwift

class SendEnterAmountViewController: UIViewController {

	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var addressAliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var textfield: ValidatorTextField!
	@IBOutlet weak var errorMessage: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var fiatValue: UILabel!
	@IBOutlet weak var feeValue: UILabel!
	@IBOutlet weak var reviewButton: UIButton!
	
	private var isToken = false
	private let textfieldLeftView = UIView()
	private let textfieldRightView = UIView()
	private let maxButton = UIButton()
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		addressAliasLabel.text = TransactionService.shared.sendData.destinationAlias
		addressLabel.text = TransactionService.shared.sendData.destination
		
		if let token = TransactionService.shared.sendData.chosenToken {
			isToken = true
			balanceLabel.text = "Balance: " + token.balance.normalisedRepresentation + " \(token.symbol)"
			textfield.validator = TokenAmountValidator(balanceLimit: token.balance, decimalPlaces: token.decimalPlaces)
			fiatValue.text = " "
			feeValue.text = " "
			
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT {
			isToken = false
			balanceLabel.text = "Balance: " + nft.balance.description
			textfield.validator = TokenAmountValidator(balanceLimit: TokenAmount(fromNormalisedAmount: nft.balance, decimalPlaces: 0), decimalPlaces: 0)
			fiatValue.text = "..."
			feeValue.text = " "
			
		} else {
			balanceLabel.text = ""
		}
		
		errorMessage.text = ""
		fiatLabel.text = DependencyManager.shared.coinGeckoService.selectedCurrency.uppercased() + ":"
		
		reviewButton.isEnabled = false
		
		setupTextField()
	}
	
	func setupTextField() {
		textfield.leftViewMode = .always
		textfield.validatorTextFieldDelegate = self
		
		let image = UIImageView(frame: CGRect(x: 5, y: 0, width: 40, height: 30))
		image.translatesAutoresizingMaskIntoConstraints = false
		image.contentMode = .scaleAspectFit
		image.image = UIImage(named: "tezos-xtz-logo")
		
		textfieldLeftView.translatesAutoresizingMaskIntoConstraints = false
		textfieldLeftView.frame = CGRect(x: 0, y: 0, width: 50, height: 40)
		textfieldLeftView.addSubview(image)
		
		NSLayoutConstraint.activate([
			image.widthAnchor.constraint(equalToConstant: 40),
			image.heightAnchor.constraint(equalToConstant: 30),
			image.centerXAnchor.constraint(equalTo: textfieldLeftView.centerXAnchor, constant: 0),
			image.centerYAnchor.constraint(equalTo: textfieldLeftView.centerYAnchor, constant: 0),
			textfieldLeftView.widthAnchor.constraint(equalToConstant: 50),
			textfieldLeftView.heightAnchor.constraint(equalToConstant: 40),
		])
		
		textfield.leftView = textfieldLeftView
		
		maxButton.translatesAutoresizingMaskIntoConstraints = false
		maxButton.frame = CGRect(x: 0, y: 0, width: 75, height: 40)
		maxButton.setTitle("MAX", for: .normal)
		maxButton.addTarget(self, action: #selector(setMax), for: .touchUpInside)
		maxButton.borderWidth = 1
		maxButton.borderColor = .lightGray
		maxButton.customCornerRadius = 20
		maxButton.setTitleColor(.lightGray, for: .normal)
		
		textfieldRightView.translatesAutoresizingMaskIntoConstraints = false
		textfieldRightView.frame = CGRect(x: 0, y: 0, width: 85, height: 40)
		textfieldRightView.addSubview(maxButton)
		
		NSLayoutConstraint.activate([
			maxButton.widthAnchor.constraint(equalToConstant: 75),
			maxButton.heightAnchor.constraint(equalToConstant: 40),
			maxButton.centerXAnchor.constraint(equalTo: textfieldRightView.centerXAnchor, constant: 0),
			maxButton.centerYAnchor.constraint(equalTo: textfieldRightView.centerYAnchor, constant: 0),
			textfieldRightView.widthAnchor.constraint(equalToConstant: 85),
			textfieldRightView.heightAnchor.constraint(equalToConstant: 40),
		])
		
		textfield.rightViewMode = .always
		textfield.rightView = textfieldRightView
		
		textfield.customCornerRadius = textfield.frame.height / 2
		textfield.maskToBounds = true
		textfield.addDoneToolbar(onDone: (target: self, action: #selector(estimateFee)))
	}
	
	@objc func setMax() {
		if let components = balanceLabel.text?.components(separatedBy: " "), components.count > 1 {
			textfield.text = components[1]
			if textfield.revalidateTextfield() {
				estimateFee()
			}
		}
	}
	
	@objc func estimateFee() {
		textfield.resignFirstResponder()
		
		guard let wallet = DependencyManager.shared.selectedWallet, let destination = TransactionService.shared.sendData.destination else {
			self.alert(errorWithMessage: "Can't find wallet")
			return
		}
		
		if isToken, let token = TransactionService.shared.sendData.chosenToken, let textDecimal = Decimal(string: textfield.text ?? "") {
			
			let amount = TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces)
			let operations = OperationFactory.sendOperation(amount, of: token, from: wallet.address, to: destination)
			
			self.showLoadingView(completion: nil)
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] estimationResult in
				self?.hideLoadingView()
				
				switch estimationResult {
					case .success(let estimatedOperations):
						TransactionService.shared.sendData.operations = estimatedOperations
						self?.feeValue.text = estimatedOperations.map({ $0.operationFees?.allFees() ?? .zero() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " XTZ"
						self?.reviewButton.isEnabled = true
						
					case .failure(let estimationError):
						self?.alert(errorWithMessage: "\(estimationError)")
						self?.reviewButton.isEnabled = false
				}
			}
		} else if !isToken, let nft = TransactionService.shared.sendData.chosenNFT, let textDecimal = Decimal(string: textfield.text ?? "") {
			
			let operations = OperationFactory.sendOperation(textDecimal, of: nft, from: wallet.address, to: destination)
			
			self.showLoadingView(completion: nil)
			
			// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
			DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] estimationResult in
				self?.hideLoadingView()
				
				switch estimationResult {
					case .success(let estimatedOperations):
						TransactionService.shared.sendData.operations = estimatedOperations
						self?.feeValue.text = estimatedOperations.map({ $0.operationFees?.allFees() ?? .zero() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " XTZ"
						self?.reviewButton.isEnabled = true
						
					case .failure(let estimationError):
						self?.alert(errorWithMessage: "\(estimationError)")
						self?.reviewButton.isEnabled = false
				}
			}
		}
	}
}

extension SendEnterAmountViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		estimateFee()
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			textfield.borderColor = .lightGray
			textfield.borderWidth = 0
			errorMessage.text = ""
			
			if isToken, let token = TransactionService.shared.sendData.chosenToken, let textDecimal = Decimal(string: text) {
				self.fiatValue.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: TokenAmount(fromNormalisedAmount: textDecimal, decimalPlaces: token.decimalPlaces))
			}
			
		} else if text != "" {
			textfield.borderColor = .red
			textfield.borderWidth = 1
			errorMessage.text = "Invalid amount"
			
			if isToken {
				self.fiatValue.text = "0"
			}
		}
	}
}
