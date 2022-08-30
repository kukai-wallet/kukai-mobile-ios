//
//  AddLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

class AddLiquidityViewController: UIViewController {

	@IBOutlet weak var token1Icon: UIImageView!
	@IBOutlet weak var token1Button: UIButton!
	@IBOutlet weak var token1Textfield: ValidatorTextField!
	@IBOutlet weak var token1BalanceLabel: UILabel!
	@IBOutlet weak var token1MaxButton: UIButton!
	
	@IBOutlet weak var token2Icon: UIImageView!
	@IBOutlet weak var token2Button: UIButton!
	@IBOutlet weak var token2Textfield: ValidatorTextField!
	@IBOutlet weak var token2BalanceLabel: UILabel!
	@IBOutlet weak var token2MaxButton: UIButton!
	
	@IBOutlet weak var addButton: UIButton!
	
	private let viewModel = AddLiquidityViewModel()
	private var cancellable: AnyCancellable?
	
	
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
		
		token1Textfield.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		token1Textfield.validatorTextFieldDelegate = self
		token2Textfield.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		token2Textfield.validatorTextFieldDelegate = self
		
		addButton.isHidden = viewModel.isAddButtonHidden
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		TransactionService.shared.currentTransactionType = .addLiquidity
		
		viewModel.defaultToFirstAvilableTokenIfNoneSelected()
		viewModel.updateTokenInfo()
		updateUI()
		
		viewModel.refreshExchangeRates { [weak self] in
			if self?.token1Textfield.text != "" {
				self?.viewModel.calculateReturn(input1: self?.token1Textfield.text, input2: nil)
			} else {
				self?.viewModel.calculateReturn(input1: nil, input2: self?.token2Textfield.text)
			}
		}
	}
	
	func updateUI() {
		token1Button.setTitle(viewModel.token1Title, for: .normal)
		token1Textfield.validator = viewModel.token1Validator
		token1BalanceLabel.text = viewModel.token1BalanceText
		token1Textfield.text = viewModel.token1TextfieldInput
		
		if !token1Textfield.isFirstResponder {
			token1Textfield.text = viewModel.token1TextfieldInput
		}
		
		if let img = viewModel.token1IconImage {
			token1Icon.image = img
		} else if let url = viewModel.token1IconURL {
			MediaProxyService.load(url: url, to: token1Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: token1Icon.frame.size)
		}
		
		token2Button.setTitle(viewModel.token2Title, for: .normal)
		token2Textfield.validator = viewModel.token2Validator
		token2BalanceLabel.text = viewModel.token2BalanceText
		
		if !token2Textfield.isFirstResponder {
			token2Textfield.text = viewModel.token2TextfieldInput
		}
		
		if let img = viewModel.token2IconImage {
			token2Icon.image = img
		} else if let url = viewModel.token2IconURL {
			MediaProxyService.load(url: url, to: token2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: token2Icon.frame.size)
		}
		
		addButton.isHidden = viewModel.isAddButtonHidden
	}
	
	@objc func estimate() {
		token1Textfield.resignFirstResponder()
		token2Textfield.resignFirstResponder()
		viewModel.estimate()
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func token2ButtonTapped(_ sender: Any) {
	}
	
	@IBAction func token1MaxTapped(_ sender: Any) {
		let balLimit = (token1Textfield.validator as? TokenAmountValidator)?.balanceLimit
		token1Textfield.text = balLimit?.normalisedRepresentation
		
		let _ = token1Textfield.revalidateTextfield()
		viewModel.estimate()
	}
	
	@IBAction func token2MaxTapped(_ sender: Any) {
		let balLimit = (token2Textfield.validator as? TokenAmountValidator)?.balanceLimit
		token2Textfield.text = balLimit?.normalisedRepresentation
		
		let _ = token2Textfield.revalidateTextfield()
		viewModel.estimate()
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
			viewModel.calculateReturn(input1: text, input2: nil)
			updateUI()
			
		} else if validated {
			viewModel.calculateReturn(input1: nil, input2: text)
			updateUI()
		}
	}
}
