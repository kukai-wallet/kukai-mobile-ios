//
//  DeviceConnectedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/08/2024.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import Combine

class DeviceConnectedViewController: UIViewController {
	
	@IBOutlet weak var spinnerImage: UIImageView!
	@IBOutlet weak var instructionLabel: UILabel!
	@IBOutlet weak var addressVerificationLabel: UILabel!
	@IBOutlet weak var accountScanStackView: UIStackView!
	@IBOutlet weak var numberLabel: UILabel!
	@IBOutlet weak var actionButton: CustomisableButton!
	
	private var bag = Set<AnyCancellable>()
	private var address: String? = nil
	private var publicKey: String? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		addressVerificationLabel.isHidden = true
		accountScanStackView.isHidden = true
		numberLabel.text = "0"
		actionButton.isHidden = true
		actionButton.setTitle("Try Again", for: .normal)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		spinnerImage.rotate360Degrees()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		checkConnected()
	}
	
	@IBAction func actionButtonTapped(_ sender: Any) {
		checkConnected()
	}
	
	private func hideAllInstrunctionUI() {
		instructionLabel.isHidden = true
		addressVerificationLabel.isHidden = true
		accountScanStackView.isHidden = true
		
		actionButton.setTitle("Try again", for: .normal)
		actionButton.isHidden = false
	}
	
	private func checkConnected() {
		self.instructionLabel.text = "Checking device ..."
		self.instructionLabel.isHidden = false
		
		guard let chosenUUID = TransactionService.shared.ledgerSetupData.selectedUUID else {
			self.windowError(withTitle: "error".localized(), description: "Unable to locate selected device")
			self.navigationController?.popViewController(animated: true)
			return
		}
		
		if chosenUUID == LedgerService.shared.getConnectedDeviceUUID() {
			startStep1()
			
		} else {
			LedgerService.shared.connectTo(uuid: chosenUUID)
				.sink(onError: { [weak self] error in
					self?.windowError(withTitle: "error".localized(), description: "Ledger device disconnected. Please check Bluetooth is enabled and try again")
					
				}, onSuccess: { [weak self] success in
					if !success {
						self?.windowError(withTitle: "error".localized(), description: "Unable to connect to device, please try again")
						return
					}
				})
				.store(in: &bag)
		}
	}
	
	private func startStep1() {
		LedgerService.shared.getAddress(verify: false)
			.onReceiveOutput { [weak self] addressObj in
				self?.instructionLabel.text = "Please verify on the Ledger device that the below address is being displayed"
				self?.addressVerificationLabel.text = addressObj.address
				self?.addressVerificationLabel.isHidden = false
			}
			.flatMap { _ in
				return LedgerService.shared.getAddress(verify: true)
			}
			.sink(onError: { [weak self] error in
				self?.windowError(withTitle: "error".localized(), description: "Ledger device returned an error. Please verify that it has been setup with the Ledger Live app, the Tezos app is installed, and setup.\n\n\(error)")
				self?.hideAllInstrunctionUI()
				
			}, onSuccess: { [weak self] addressObj2 in
				self?.address = addressObj2.address
				self?.publicKey = addressObj2.publicKey
				self?.startStep2()
			})
			.store(in: &bag)
	}
	
	private func startStep2() {
		guard let uuid = TransactionService.shared.ledgerSetupData.selectedUUID,
			  let address = self.address,
			  let publicKey = self.publicKey,
			  let wallet = LedgerWallet(address: address, publicKey: publicKey, derivationPath: HD.defaultDerivationPath, curve: .ed25519, ledgerUUID: uuid) else {
			self.windowError(withTitle: "error".localized(), description: "Unable to create new wallet. Please try again")
			self.hideAllInstrunctionUI()
			return
		}
		
		instructionLabel.isHidden = true
		addressVerificationLabel.isHidden = true
		accountScanStackView.isHidden = false
		
		Task {
			let errorString = await WalletManagementService.cacheWalletAndScanForAccounts(wallet: wallet, uuid: uuid, progress: { [weak self] found in
				DispatchQueue.main.async { [weak self] in
					self?.numberLabel.text = (found + 1).description
				}
			})
			
			if let eString = errorString {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
					self?.hideAllInstrunctionUI()
					self?.windowError(withTitle: "error".localized(), description: eString)
				}
			} else {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
					self?.navigate()
				}
			}
		}
	}
	
	private func navigate() {
		let viewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		if let vc = viewController {
			self.navigationController?.popToViewController(vc, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}
