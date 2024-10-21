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
	
	public enum DeviceConnectedViewControllerError: Error {
		case migrateInvalidWallet
	}
	
	@IBOutlet weak var spinnerImage: UIImageView!
	@IBOutlet weak var instructionLabel: UILabel!
	@IBOutlet weak var addressVerificationLabel: UILabel!
	@IBOutlet weak var accountScanStackView: UIStackView!
	@IBOutlet weak var errorStackView: UIStackView!
	@IBOutlet weak var numberLabel: UILabel!
	@IBOutlet weak var actionButton: CustomisableButton!
	
	private var bag = Set<AnyCancellable>()
	private var address: String? = nil
	private var publicKey: String? = nil
	
	public var walletToMigrate: WalletMetadata? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		addressVerificationLabel.isHidden = true
		accountScanStackView.isHidden = true
		numberLabel.text = "0"
		actionButton.customButtonType = .primary
		actionButton.isHidden = true
		actionButton.setTitle("Try Again", for: .normal)
		errorStackView.isHidden = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		spinnerImage.rotate360Degrees()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		checkConnected()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if self.isMovingFromParent {
			LedgerService.shared.disconnectFromDevice()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? MigrateLedgerViewController {
			vc.walletToMigrate = walletToMigrate
			vc.newUUID = TransactionService.shared.ledgerSetupData.selectedUUID
		}
	}
	
	@IBAction func actionButtonTapped(_ sender: Any) {
		checkConnected()
	}
	
	private func hideAllInstrunctionUI(showConnectionError: Bool) {
		instructionLabel.isHidden = true
		addressVerificationLabel.isHidden = true
		accountScanStackView.isHidden = true
		
		actionButton.setTitle("Try again", for: .normal)
		actionButton.isHidden = false
		
		errorStackView.isHidden = !showConnectionError
	}
	
	private func checkConnected() {
		self.instructionLabel.text = "Checking device ..."
		self.instructionLabel.isHidden = false
		self.errorStackView.isHidden = true
		self.actionButton.isHidden = true
		
		guard let chosenUUID = TransactionService.shared.ledgerSetupData.selectedUUID else {
			hideAllInstrunctionUI(showConnectionError: true)
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
		if walletToMigrate != nil {
			processStep1Migrate()
			
		} else {
			processStep1Onboarding()
		}
	}
	
	private func processStep1Onboarding() {
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
				self?.hideAllInstrunctionUI(showConnectionError: true)
				
			}, onSuccess: { [weak self] addressObj2 in
				self?.address = addressObj2.address
				self?.publicKey = addressObj2.publicKey
				self?.startStep2()
			})
			.store(in: &bag)
	}
	
	private func processStep1Migrate() {
		LedgerService.shared.getAddress(verify: false)
			.sink(onError: { [weak self] error in
				self?.windowError(withTitle: "error".localized(), description: "Ledger device returned an error. Please verify that it has been setup with the Ledger Live app, the Tezos app is installed, and setup.\n\n\(error)")
				self?.hideAllInstrunctionUI(showConnectionError: true)
				
			}, onSuccess: { [weak self] addressObj in
				if addressObj.address == self?.walletToMigrate?.address {
					self?.performSegue(withIdentifier: "migrate", sender: nil)
					
				} else {
					self?.windowError(withTitle: "error".localized(), description: "error-ledger-migrate-invalid".localized())
					self?.navigationController?.popViewController(animated: true)
				}
			})
			.store(in: &bag)
	}
	
	private func startStep2() {
		guard let uuid = TransactionService.shared.ledgerSetupData.selectedUUID,
			  let address = self.address,
			  let publicKey = self.publicKey,
			  let wallet = LedgerWallet(address: address, publicKey: publicKey, derivationPath: HD.defaultDerivationPath, curve: .ed25519, ledgerUUID: uuid) else {
			self.windowError(withTitle: "error".localized(), description: "Unable to create new wallet. Please try again")
			self.hideAllInstrunctionUI(showConnectionError: false)
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
					self?.hideAllInstrunctionUI(showConnectionError: false)
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
		LedgerService.shared.disconnectFromDevice()
		let viewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		if let vc = viewController {
			self.navigationController?.popToViewController(vc, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}
