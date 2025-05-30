//
//  ExperimentalNetworkViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2025.
//

import UIKit
import KukaiCoreSwift

class ExperimentalNetworkViewController: UIViewController {
	
	// https://rpc.rionet.teztnets.com
	// https://api.rionet.tzkt.io/
	
	@IBOutlet weak var nodeURLTextfield: ValidatorTextField!
	@IBOutlet weak var nodeURLErrorLabel: UILabel!
	@IBOutlet weak var tzktAPITextfield: ValidatorTextField!
	@IBOutlet weak var tzktAPIErrorLabel: UILabel!
	@IBOutlet weak var continueButton: CustomisableButton!
	
	private var nodeClient: TezosNodeClient? = nil
	private var tzktClient: TzKTClient? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		nodeURLTextfield.validatorTextFieldDelegate = self
		nodeURLTextfield.validator = URLValidator()
		nodeURLErrorLabel.isHidden = true
		tzktAPITextfield.validatorTextFieldDelegate = self
		tzktAPITextfield.validator = URLValidator()
		tzktAPIErrorLabel.isHidden = true
		
		continueButton.customButtonType = .primary
		
		nodeURLTextfield.text = DependencyManager.shared.experimentalNodeUrl?.absoluteString ?? ""
		tzktAPITextfield.text = DependencyManager.shared.experimentalTzktUrl?.absoluteString ?? ""
		let _ = nodeURLTextfield.revalidateTextfield()
		
		continueButton.isEnabled = isEverythingValid()
    }
	
	@IBAction func continueTapped(_ sender: Any) {
		checkURLsWork { [weak self] success in
			if success {
				DependencyManager.shared.experimentalNodeUrl = URL(string: self?.nodeURLTextfield.text ?? "")
				
				if let string = self?.tzktAPITextfield.text {
					DependencyManager.shared.experimentalTzktUrl = URL(string: string)
					DependencyManager.shared.experimentalExplorerUrl = URL(string: string.replacingOccurrences(of: "api.", with: ""))
				} else {
					DependencyManager.shared.experimentalTzktUrl = nil
					DependencyManager.shared.experimentalExplorerUrl = nil
				}
				
				
				DependencyManager.shared.setNetworkTo(networkTo: .experimental)
				self?.navigationController?.popToHome()
			}
		}
	}
	
	// Check we can fetch network information from the node, and if TzKT URL provided, check we can fetch the list of cycles, as a test to ensure everything working correctly
	func checkURLsWork(completion: @escaping ((Bool) -> Void)) {
		guard let nodeURL = URL(string: nodeURLTextfield.text ?? "") else {
			self.windowError(withTitle: "error".localized(), description: "Unable to process node URL. Please try again")
			return
		}
		
		self.showLoadingView()
		let config = TezosNodeClientConfig.configWithLocalForge(nodeURLs: [nodeURL], tzktURL: URL(string: tzktAPITextfield.text ?? ""), tezosDomainsURL: nil, objktApiURL: nil, urlSession: .shared, networkType: .experimental)
		nodeClient = TezosNodeClient(config: config)
		
		nodeClient?.getNetworkInformation(completion: { [weak self] success, error in
			if let err = error {
				self?.windowError(withTitle: "error".localized(), description: "Unable to fetch network information from node: \(err)")
				self?.hideLoadingView()
				completion(false)
				
			} else if (self?.tzktAPITextfield.text?.count ?? 0) > 0, let nodeClient = self?.nodeClient {
				self?.tzktClient = TzKTClient(networkService: nodeClient.networkService, config: config, dipDupClient: DipDupClient(networkService: nodeClient.networkService, config: config))
				self?.tzktClient?.cycles(completion: { result in
					self?.hideLoadingView()
					
					guard let _ = try? result.get() else {
						self?.windowError(withTitle: "error".localized(), description: "TzKT API test failed: \(result.getFailure())")
						completion(false)
						return
					}
					
					completion(true)
				})
				
			} else {
				self?.hideLoadingView()
				completion(true)
			}
		})
	}
}

extension ExperimentalNetworkViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		textField.text = ""
		textField.resignFirstResponder()
		continueButton.isEnabled = isEverythingValid()
		
		return false
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		
		if !validated {
			if textfield == nodeURLTextfield {
				nodeURLErrorLabel.text = "Invalid URL"
				nodeURLErrorLabel.isHidden = false
			} else {
				tzktAPITextfield.text = "Invalid URL"
				tzktAPIErrorLabel.isHidden = false
			}
		} else {
			if textfield == nodeURLTextfield {
				nodeURLErrorLabel.isHidden = true
			} else {
				tzktAPIErrorLabel.isHidden = true
			}
		}
		
		continueButton.isEnabled = isEverythingValid()
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	private func isEverythingValid() -> Bool {
		return ((nodeURLTextfield.text?.count ?? 0) > 0 && nodeURLTextfield.isValid) && (tzktAPITextfield.text?.count == 0 || ((tzktAPITextfield.text?.count ?? 0) > 0 && tzktAPITextfield.isValid))
	}
}
