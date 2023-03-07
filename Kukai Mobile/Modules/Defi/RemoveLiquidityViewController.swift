//
//  RemoveLiquidityViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/07/2022.
//

import UIKit
import KukaiCoreSwift
import Combine

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
	
	private let viewModel = RemoveLiquidityViewModel()
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
		
		lpTokenTextfield.addDoneToolbar(onDone: (target: self, action: #selector(estimate)))
		lpTokenTextfield.validatorTextFieldDelegate = self
		
		removeButton.isHidden = viewModel.isRemoveButtonHidden
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		TransactionService.shared.currentTransactionType = .removeLiquidity
		
		viewModel.defaultToFirstAvilableTokenIfNoneSelected()
		viewModel.updateTokenInfo()
		updateUI()
		
		viewModel.refreshExchangeRates { [weak self] in
			self?.viewModel.calculateReturn(fromInput: self?.lpTokenTextfield.text)
		}
	}
	
	func updateUI() {
		lpTokenButton.setTitle(viewModel.lpTokenTitle, for: .normal)
		lpTokenTextfield.validator = viewModel.lpTokenValidator
		lpTokenBalance.text = viewModel.lpTokenBalanceText
		
		if let img = viewModel.lpToken1IconImage {
			lpToken1Icon.image = img
			outputToken1Icon.image = img
		}
		
		if let url = viewModel.lpToken2IconURL {
			MediaProxyService.load(url: url, to: lpToken2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: lpToken2Icon.frame.size)
			MediaProxyService.load(url: url, to: outputToken2Icon, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: outputToken2Icon.frame.size)
		}
		
		outputToken1Button.setTitle(viewModel.outputToken1Title, for: .normal)
		outputToken1Balance.text = viewModel.outputToken1BalanceText
		outputToken1Textfield.text = viewModel.outputToken1TextfieldInput
		
		outputToken2Button.setTitle(viewModel.outputToken2Title, for: .normal)
		outputToken2Balance.text = viewModel.outputToken2BalanceText
		outputToken2Textfield.text = viewModel.outputToken2TextfieldInput
		
		removeButton.isHidden = viewModel.isRemoveButtonHidden
	}
	
	@objc func estimate() {
		lpTokenTextfield.resignFirstResponder()
		viewModel.estimate()
	}
	
	
	
	// MARK: - Actions
	
	@IBAction func lpTokenTapped(_ sender: Any) {
	}
	
	@IBAction func lpTokenMaxTapped(_ sender: Any) {
		let balLimit = (lpTokenTextfield.validator as? TokenAmountValidator)?.balanceLimit
		lpTokenTextfield.text = balLimit?.normalisedRepresentation
		
		let _ = lpTokenTextfield.revalidateTextfield()
		viewModel.estimate()
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
			viewModel.calculateReturn(fromInput: text)
			updateUI()
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
