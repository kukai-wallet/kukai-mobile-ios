//
//  SwapViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

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
	
	@IBOutlet weak var previewButton: UIButton!
	
	private let viewModel = SwapViewModel()
	private var cancellable: AnyCancellable?
	
	
	// MARK: - Setup
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		cancellable = viewModel.$state.sink { [weak self] state in
			switch state {
				case .loading:
					self?.showLoadingModal()
					
				case .failure(_, let errorString):
					self?.hideLoadingModal()
					self?.alert(withTitle: "Error", andMessage: errorString)
					self?.updateUI()
					
				case .success:
					self?.hideLoadingModal()
					self?.updateUI()
			}
		}
		
		tokenFromTextField.validatorTextFieldDelegate = self
		tokenFromTextField.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		
		previewButton.isHidden = viewModel.isPreviewHidden
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		TransactionService.shared.currentTransactionType = .exchange
		
		viewModel.defaultToFirstAvilableTokenIfNoneSelected()
		viewModel.updateTokenInfo()
		updateUI()
		
		viewModel.refreshExchangeRates { [weak self] in
			self?.viewModel.calculateReturn(fromInput: self?.tokenFromTextField.text)
		}
	}
	
	func updateUI() {
		tokenFromButton.setTitle(viewModel.tokenFromTitle, for: .normal)
		tokenFromTextField.validator = viewModel.tokenFromValidator
		tokenFromBalance.text = viewModel.tokenFromBalanceText
		
		if let img = viewModel.tokenFromIconImage {
			tokenFromIcon.image = img
		} else if let url = viewModel.tokenFromIconURL {
			MediaProxyService.load(url: url, to: tokenFromIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenFromIcon.frame.size)
		}
		
		tokenToButton.setTitle(viewModel.tokenToTitle, for: .normal)
		tokenToBalance.text = viewModel.tokenToBalanceText
		tokenToTextField.text = viewModel.tokenToTextfieldInput
		
		if let img = viewModel.tokenToIconImage {
			tokenToIcon.image = img
		} else if let url = viewModel.tokenToIconURL {
			MediaProxyService.load(url: url, to: tokenToIcon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: tokenToIcon.frame.size)
		}
		
		exchangeRateLabel.text = viewModel.exchangeRateText
		
		previewButton.isHidden = viewModel.isPreviewHidden
	}
	
	@objc func estimate() {
		tokenFromTextField.resignFirstResponder()
		viewModel.estimate()
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func tokenFromTapped(_ sender: Any) {
		viewModel.xtzToToken = false
	}
	
	@IBAction func maxTapped(_ sender: Any) {
		let balLimit = (tokenFromTextField.validator as? TokenAmountValidator)?.balanceLimit
		tokenFromTextField.text = balLimit?.normalisedRepresentation
		
		let _ = tokenFromTextField.revalidateTextfield()
		viewModel.estimate()
	}
	
	@IBAction func tokenToTapped(_ sender: Any) {
		viewModel.xtzToToken = true
	}
	
	@IBAction func invertTokensTapped(_ sender: Any) {
		viewModel.xtzToToken = !viewModel.xtzToToken
		
		tokenFromTextField.text = ""
		tokenToTextField.text = ""
		
		viewModel.updateTokenInfo()
	}
	
	@IBAction func refreshRates(_ sender: Any) {
		viewModel.refreshExchangeRates { [weak self] in
			self?.viewModel.calculateReturn(fromInput: self?.tokenFromTextField.text)
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
			viewModel.calculateReturn(fromInput: text)
			updateUI()
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
